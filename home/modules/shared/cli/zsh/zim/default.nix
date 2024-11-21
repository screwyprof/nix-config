{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.zsh.zimfw;
in
{
  options.programs.zsh.zimfw = {
    enable = mkEnableOption "Zim - ${pkgs.zimfw.meta.description}";

    zimDir = mkOption {
      type = types.str;
      default = "$HOME/.zim";
      example = "$HOME/.cache/zim";
    };

    zimConfig = mkOption {
      type = types.str;
      default = "$HOME/.zimrc";
      example = "$HOME/.config/zsh/.zimrc";
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
    home = {
      packages = [ pkgs.zimfw ];

      activation.createZimrc = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # Create .zimrc at the configured location
        run mkdir -p $(dirname ${cfg.zimConfig})
        run cat > ${cfg.zimConfig} << 'EOL'
         ${concatStringsSep "\n" ([
           (optionalString cfg.degit ''
             zstyle ':zim:zmodule' use 'degit'
           '')
           (optionalString cfg.disableVersionCheck ''
             zstyle ':zim' disable-version-check yes
           '')
            (optionalString cfg.caseSensitive ''
              zstyle ':zim:*' case-sensitivity sensitive
            '')
         ] ++ (map (zmodule: "zmodule ${zmodule}") cfg.zmodules))}
        EOL
      '';
    };

    programs.zsh = {
      enableCompletion = mkForce false; # Let Zim handle completion

      sessionVariables = {
        ZIM_HOME = cfg.zimDir;
        ZIM_CONFIG_FILE = cfg.zimConfig;
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
