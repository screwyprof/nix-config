{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.zsh;
in
{
  options = {
    programs.zsh.zimfw = {
      enable = mkEnableOption "Zim - ${pkgs.zimfw.meta.description}";

      homeDir = mkOption {
        default = "$HOME/.zim";
        type = types.str;
        description = "Working directory for zim. It stores downloaded plugins here.";
      };

      degit = mkOption {
        default = true;
        type = types.bool;
        description = "Use degit for faster module installation";
      };

      configFile = mkOption {
        default = "$HOME/.zimrc";
        type = types.str;
        description = "Location of zimrc file";
      };

      disableVersionCheck = mkOption {
        default = false;
        type = types.bool;
        description = "Disable Zim's version check";
      };

      caseSensitivity = mkOption {
        default = "insensitive";
        type = types.enum [ "sensitive" "insensitive" ];
        description = "Case sensitivity for completions and globbing";
      };

      zmodules = mkOption {
        default = [
          # "environment"
          # "git"
          # "input"
          # "termtitle"
          # "utility"

          # "zsh-users/zsh-completions --fpath src"
          # "completion"

          # "zsh-users/zsh-autosuggestions"
          # "zsh-users/zsh-syntax-highlighting"
        ];
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
  };

  config = mkIf cfg.zimfw.enable {
    home.packages = [ pkgs.zimfw ];

    home.file.".zimrc".text = concatStringsSep "\n" ([
      # Zim settings
      (optionalString cfg.zimfw.degit ''
        zstyle ':zim:zmodule' use 'degit'
      '')
      (optionalString cfg.zimfw.disableVersionCheck ''
        zstyle ':zim' disable-version-check yes
      '')
      # Completion settings
      "zstyle ':zim' case-sensitive ${cfg.zimfw.caseSensitivity}"
      "zstyle ':zim:completion' dumpfile '${config.xdg.cacheHome}/zsh/zim-compdump'"
      "zstyle ':completion::complete:*' cache-path '${config.xdg.cacheHome}/zsh/'"
    ] ++ (map (zmodule: "zmodule ${zmodule}") cfg.zimfw.zmodules));

    programs.zsh = {
      # Disable home-manager's completion to let Zim handle it
      #enableCompletion = mkForce false;

      localVariables = {
        ZIM_HOME = cfg.zimfw.homeDir;
        ZIM_CONFIG_FILE = cfg.zimfw.configFile;
      };

      initExtraFirst = ''
        # Ensure compinit isn't loaded before Zim
        #skip_global_compinit=1
      '';

      initExtra = ''
        # Pre-Zim initialization hook
        ${cfg.zimfw.initBeforeZim}

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
        ${cfg.zimfw.initAfterZim}
      '';
    };
  };
}
