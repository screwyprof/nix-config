{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.zsh.zimfw;
  completionsCacheDir = "${config.xdg.cacheHome}/zsh";
  completionDumpFile = "${completionsCacheDir}/zcompdump";

  cachedInitScript =
    name: command:
    let
      bin = builtins.baseNameOf (builtins.head command);
    in
    pkgs.writeTextDir "share/zsh/cached-init/${name}/init.zsh" ''
      () {
        (( ''${+commands[${bin}]} )) || return 1
        local -r target=''${ZIM_HOME}/modules/${name}/cached.zsh
        local -r bin_path=''${commands[${bin}]:A}
        local -r path_file=''${target}.path
        if [[ ! -s ''${target} || ! -f ''${path_file} || "$(< ''${path_file})" != ''${bin_path} ]]; then
          mkdir -p ''${target:h}
          ${lib.escapeShellArgs command} >! ''${target} || return 1
          print -r -- ''${bin_path} >! ''${path_file}
          zcompile -UR ''${target}
        fi
        source ''${target}
      }
    '';

  zmoduleType = types.submodule {
    options = {
      path = mkOption {
        type = types.str;
        default = "";
        description = "Module path (Nix store path or zimfw built-in name)";
      };
      source = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "File to source (--source argument)";
      };
      fpath = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "fpath directory (--fpath argument)";
      };
      cachedInit = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "Command to generate init script. When set, path/source are auto-generated.";
      };
      name = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Module name for cachedInit cache directory. Defaults to basename of first command element.";
      };
    };
  };

  renderZmodule =
    mod:
    if builtins.isString mod then
      mod
    else if mod.cachedInit != null then
      let
        modName = if mod.name != null then mod.name else builtins.baseNameOf (builtins.head mod.cachedInit);
        script = cachedInitScript modName mod.cachedInit;
      in
      "${script}/share/zsh/cached-init/${modName} --source init.zsh"
    else
      "${mod.path}"
      + optionalString (mod.source != null) " --source ${mod.source}"
      + optionalString (mod.fpath != null) " --fpath ${mod.fpath}";

  # Only two valid formats:
  # 1. "$HOME/path/to/something"
  # 2. "path/to/something"
  cleanPath = path: if hasPrefix "$HOME/" path then removePrefix "$HOME/" path else path;

  zimHome = cleanPath cfg.zimDir;
  zimConfigFile = cleanPath cfg.zimConfig;

  assertions = [
    {
      assertion = !(hasPrefix "/" zimHome);
      message = "zimDir must be either relative or start with $HOME/ (got: ${cfg.zimDir})";
    }
    {
      assertion = !(hasPrefix "/" zimConfigFile);
      message = "zimConfig must be either relative or start with $HOME/ (got: ${cfg.zimConfig})";
    }
  ];

  # Define our own history search submodule
  historySearchModule = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable history substring search in Zim";
      };

      searchUpKey = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "^[[A"
          "^P"
        ];
        description = "Keys to bind to history-substring-search-up";
      };

      searchDownKey = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "^[[B"
          "^N"
        ];
        description = "Keys to bind to history-substring-search-down";
      };
    };
  };
in
{
  options.programs.zsh.zimfw = {
    enable = mkEnableOption "Zim - ${pkgs.zimfw.meta.description}";

    zimDir = mkOption {
      type = types.str;
      default = ".zim";
      example = ".cache/zim";
      description = ''
        Path to Zim's home directory, relative to user's $HOME.
        Must be inside the user's home directory.
        Will be prefixed with $HOME/ automatically.
      '';
    };

    zimConfig = mkOption {
      type = types.str;
      default = ".zimrc";
      example = ".config/zsh/.zimrc";
      description = ''
        Path to Zim's configuration file (.zimrc), relative to user's $HOME.
        Must be inside the user's home directory.
        Will be prefixed with $HOME/ automatically.
      '';
    };

    degit = mkOption {
      default = false;
      type = types.bool;
      description = "Use degit for faster module installation";
    };

    disableVersionCheck = mkOption {
      default = true;
      type = types.bool;
      description = "Disable Zim's version check";
    };

    caseSensitive = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Whether completions and globbing should be case sensitive.
        Set via ':zim:completion' and ':zim:glob' styles.
        Default is case insensitive.
      '';
    };

    zmodules = mkOption {
      default = [ ];
      type = types.listOf (types.either types.str zmoduleType);
      description = ''
        List of zimfw modules. Accepts strings (added to .zimrc verbatim) or
        structured attrsets with path/source/fpath/cachedInit fields.
      '';
    };

    initBeforeZim = mkOption {
      default = "";
      type = types.lines;
      description = "Shell commands to run before Zim initialization.";
    };

    initAfterZim = mkOption {
      default = "";
      type = types.lines;
      description = "Shell commands to run after Zim initialization.";
    };

    historySearch = mkOption {
      type = historySearchModule;
      default = { };
      description = "Zim's history substring search configuration";
    };

  };

  config = mkIf cfg.enable {
    inherit assertions;

    home = {
      packages = [ pkgs.zimfw ];

      file.${zimConfigFile}.text = builtins.concatStringsSep "\n" (
        lib.remove "" [
          (optionalString cfg.degit "zstyle ':zim:zmodule' use 'degit'")
          (optionalString cfg.disableVersionCheck "zstyle ':zim' disable-version-check yes")
          (optionalString cfg.caseSensitive "zstyle ':zim:completion' case-sensitive yes")
          (optionalString cfg.caseSensitive "zstyle ':zim:glob' case-sensitive yes")

          # Enable double-dot expansion
          "zstyle ':zim:input' double-dot-expand yes"

          # Caching
          "zstyle ':completion::complete:*' cache-path '${completionsCacheDir}'"
          "zstyle ':zim:completion' dumpfile '${completionDumpFile}'"

        ]
        ++ (map (mod: "zmodule ${renderZmodule mod}") cfg.zmodules)
      );
    };

    programs.zsh = {
      enableCompletion = mkForce false;
      historySubstringSearch.enable = mkForce false;

      sessionVariables = mkMerge [
        # Base Zim variables
        {
          ZIM_HOME = "$HOME/${zimHome}";
          ZIM_CONFIG_FILE = "$HOME/${zimConfigFile}";
        }

        # History search variables (only when enabled)
        (mkIf cfg.historySearch.enable {
          HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE = "1";
          HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS = "i";
          HISTORY_SUBSTRING_SEARCH_PREFIXED = "1";
        })
      ];

      initContent = lib.mkAfter ''
        # Pre-Zim initialization hook
        ${cfg.initBeforeZim}
        # Download zimfw plugin manager if missing
        if [[ ! -e ''${ZIM_HOME}/zimfw.zsh ]]; then
          mkdir -p ''${ZIM_HOME}
          cp ${pkgs.zimfw}/zimfw.zsh ''${ZIM_HOME}/zimfw.zsh
        fi

        # Rebuild zim init if .zimrc content has changed
        () {
          local -r hash=$(sha256sum ''${ZIM_CONFIG_FILE} 2>/dev/null || echo "none")
          local -r hash_file="''${ZIM_HOME}/.zimrc_hash"
          if [[ ! -e ''${ZIM_HOME}/init.zsh || ! -e $hash_file || "$hash" != "$(< $hash_file)" ]]; then
            source ''${ZIM_HOME}/zimfw.zsh init -q
            echo "$hash" > $hash_file
          fi
        }

        mkdir -p "${completionsCacheDir}"

        # Initialize modules
        source ''${ZIM_HOME}/init.zsh

        # Post-Zim initialization hook
        ${cfg.initAfterZim}

        ${lib.optionalString cfg.historySearch.enable ''
          ${lib.concatMapStringsSep "\n" (upKey: ''
            bindkey -r '${upKey}'
            bindkey '${upKey}' history-substring-search-up'') cfg.historySearch.searchUpKey}
          ${lib.concatMapStringsSep "\n" (downKey: ''
            bindkey -r '${downKey}'
            bindkey '${downKey}' history-substring-search-down'') cfg.historySearch.searchDownKey}
        ''}
      '';
    };
  };
}
