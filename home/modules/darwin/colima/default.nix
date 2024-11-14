{ config, lib, pkgs, ... }:

let
  defaultProfile = "docker";
  
  # Centralize paths and configuration
  paths = {
    logDir = "${config.home.homeDirectory}/.colima/${defaultProfile}";
    configDir = "${config.home.homeDirectory}/.colima";
    wrapperScript = "${config.home.homeDirectory}/.local/bin/colima-wrapper.sh";
  };

  # LaunchAgent configuration
  agent = {
    label = "org.nix-community.home.colima";
    plist = "${config.home.homeDirectory}/Library/LaunchAgents/${agent.label}.plist";
  };

  # Centralize environment variables
  envVars = {
    HOME = config.home.homeDirectory;
    COLIMA_HOME = paths.configDir;
    COLIMA_PROFILE = defaultProfile;
    COLIMA_LOG_ROTATE = "true";
    COLIMA_LOG_SIZE = "10M";
    PATH = lib.makeBinPath [
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnugrep
      pkgs.gettext
      pkgs.bash
      pkgs.docker
      pkgs.colima
    ] + ":/usr/bin:/usr/sbin";  # System commands from macOS
  };
in
{
  home = {
    packages = with pkgs; [ colima ];

    file = {
      ".colima/docker/colima.yaml".source = ./configs/docker.yaml;
      ".colima/k8s/colima.yaml".source = ./configs/k8s.yaml;
      ".local/bin/colima-wrapper.sh".source = ./scripts/colima-wrapper.sh;
    };

    activation = {
      cleanupColima = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        export PATH="${envVars.PATH}"

        echo "Checking initial state..."
        "${paths.wrapperScript}" ${defaultProfile} status

        echo "Unloading existing Colima agent..."
        /bin/launchctl bootout gui/$UID "${agent.plist}" 2>/dev/null || true

        # Clean up any remaining agent files
        rm -f "${agent.plist}" || true

        echo "Cleaning up Colima..."
        "${paths.wrapperScript}" ${defaultProfile} clean

        echo "Checking post-cleanup state..."
        "${paths.wrapperScript}" ${defaultProfile} status
      '';
    };
  };

  launchd.agents.colima = {
    enable = true;
    config = {
      Label = agent.label;
      ProgramArguments = [
        paths.wrapperScript
        defaultProfile
        "daemon"
      ];
      RunAtLoad = true;
      StandardOutPath = "${paths.logDir}/colima.log";
      StandardErrorPath = "${paths.logDir}/colima.error.log";
      EnvironmentVariables = envVars;
      KeepAlive = {
        Crashed = true;
        SuccessfulExit = false;
      };
      ThrottleInterval = 30;
      # Additional recommended LaunchAgent settings
      ProcessType = "Interactive";
      LimitLoadToSessionType = "Aqua";
      Nice = 0;
    };
  };

  programs.zsh.shellAliases = let
    mkColimaAlias = cmd: "colima ${cmd} -p";
  in {
    cstart = mkColimaAlias "start";
    cstop = mkColimaAlias "stop";
    cstatus = mkColimaAlias "status";
    cdelete = mkColimaAlias "delete";
    clist = "colima list";
    clog = "tail -f ${paths.logDir}/colima.log";
    clogerr = "tail -f ${paths.logDir}/colima.error.log";
  };
}
