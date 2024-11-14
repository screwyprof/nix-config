{ config, lib, pkgs, ... }:

let
  # Basic configuration
  defaultProfile = "docker";
  homeDir = config.home.homeDirectory;

  # Centralize paths
  paths = {
    logDir = "${homeDir}/.colima/${defaultProfile}";
    configDir = "${homeDir}/.colima";
    wrapperScript = "${homeDir}/.local/bin/colima-wrapper.sh";
  };

  # LaunchAgent configuration
  agent = {
    label = "org.nix-community.home.colima";
    plist = "${homeDir}/Library/LaunchAgents/${agent.label}.plist";
  };

  # Required packages for the PATH
  requiredPackages = with pkgs; [
    coreutils
    findutils
    gnugrep
    gettext
    bash
    nix
    docker
    colima
  ];

  # Environment variables
  envVars = {
    HOME = homeDir;
    COLIMA_HOME = paths.configDir;
    COLIMA_PROFILE = defaultProfile;
    COLIMA_LOG_ROTATE = "true";
    COLIMA_LOG_SIZE = "10M";
    PATH = lib.makeBinPath requiredPackages + ":/usr/bin:/usr/sbin";
  };

  # Create the wrapper script
  wrapperScript = pkgs.writeScriptBin "colima-wrapper.sh" (builtins.readFile ./scripts/colima-wrapper.sh);
in
{
  home = {
    packages = with pkgs; [
      colima
      wrapperScript
    ];

    # File management
    file = {
      ".colima/docker/colima.yaml".source = ./configs/docker.yaml;
      ".colima/k8s/colima.yaml".source = ./configs/k8s.yaml;
    };

    # Activation script
    activation.cleanupColima = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      export PATH="${envVars.PATH}"

      echo "Checking initial state..."
      "${paths.wrapperScript}" ${defaultProfile} status

      echo "Unloading existing Colima agent..."
      /bin/launchctl bootout gui/$UID "${agent.plist}" 2>/dev/null || true
      rm -f "${agent.plist}" || true

      echo "Cleaning up Colima..."
      "${paths.wrapperScript}" ${defaultProfile} clean

      echo "Checking post-cleanup state..."
      "${paths.wrapperScript}" ${defaultProfile} status
    '';
  };

  # LaunchAgent configuration
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

  programs.zsh.shellAliases =
    let
      mkColimaAlias = cmd: "colima ${cmd} -p";
    in
    {
      cstart = mkColimaAlias "start";
      cstop = mkColimaAlias "stop";
      cstatus = mkColimaAlias "status";
      cdelete = mkColimaAlias "delete";
      clist = "colima list";
      clog = "tail -f ${paths.logDir}/colima.log";
      clogerr = "tail -f ${paths.logDir}/colima.error.log";
    };
}
