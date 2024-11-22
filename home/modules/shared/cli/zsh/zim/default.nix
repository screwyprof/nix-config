{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.zsh.zimfw;

  # Only two valid formats:
  # 1. "$HOME/path/to/something"
  # 2. "path/to/something"
  cleanPath = path:
    if hasPrefix "$HOME/" path
    then removePrefix "$HOME/" path
    else path;

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
      type = types.listOf types.str;
      description = "List of zimfw modules. These are added to .zimrc verbatim.";
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
  };

  config = mkIf cfg.enable {
    inherit assertions;

    home = {
      packages = [ pkgs.zimfw ];

      file.${zimConfigFile}.text = concatStringsSep "\n" (
        lib.remove "" [
          (optionalString cfg.degit "zstyle ':zim:zmodule' use 'degit'")
          (optionalString cfg.disableVersionCheck "zstyle ':zim' disable-version-check yes")
          (optionalString cfg.caseSensitive "zstyle ':zim:completion' case-sensitive yes")
          (optionalString cfg.caseSensitive "zstyle ':zim:glob' case-sensitive yes")
        ] ++ (map (zmodule: "zmodule ${zmodule}") cfg.zmodules)
      );
    };

    programs.zsh = {
      enableCompletion = mkForce false;

      sessionVariables = {
        ZIM_HOME = "$HOME/${zimHome}";
        ZIM_CONFIG_FILE = "$HOME/${zimConfigFile}";
      };

      initExtra = lib.mkAfter ''
        # Pre-Zim initialization hook
        ${cfg.initBeforeZim}

        # Download zimfw plugin manager if missing
        if [[ ! -e ''${ZIM_HOME}/zimfw.zsh ]]; then
          mkdir -p ''${ZIM_HOME}
          cp ${pkgs.zimfw}/zimfw.zsh ''${ZIM_HOME}/zimfw.zsh
        fi

        # Create a hash of current .zimrc content
        _zimrc_hash=$(sha256sum ''${ZIM_CONFIG_FILE} 2>/dev/null || echo "none")
        _saved_hash_file="''${ZIM_HOME}/.zimrc_hash"

        # Check if .zimrc content has changed
        if [[ ! -e ''${ZIM_HOME}/init.zsh || ! -e $_saved_hash_file || "$_zimrc_hash" != "$(cat $_saved_hash_file 2>/dev/null)" ]]; then
          source ''${ZIM_HOME}/zimfw.zsh init -q
          echo "$_zimrc_hash" > $_saved_hash_file
        fi

        # Initialize modules
        source ''${ZIM_HOME}/init.zsh

        # Post-Zim initialization hook
        ${cfg.initAfterZim}
      '';
    };
  };
}
