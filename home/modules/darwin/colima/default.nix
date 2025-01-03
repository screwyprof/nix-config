{ config, lib, pkgs, ... }:

let
  # Basic configuration
  defaultProfile = "docker";
  homeDir = config.home.homeDirectory;

  # Create the wrapper script
  wrapperScript = pkgs.writeScriptBin "colima-wrapper.sh" (builtins.readFile ./scripts/colima-wrapper.sh);

  # Required packages
  requiredPackages = with pkgs; [
    coreutils
    findutils
    flock
    bash
    docker
    colima
    wrapperScript
  ];

  paths = {
    colimaConfigDir = "${config.xdg.configHome}/colima";
    currentProfileDir = "${config.xdg.configHome}/colima/${defaultProfile}";
    wrapperScript = lib.getExe wrapperScript;
    systemPath = lib.makeBinPath requiredPackages + ":/usr/bin:/usr/sbin";
  };

  agent = {
    label = "org.nix-community.home.colima";
    plist = "${homeDir}/Library/LaunchAgents/${agent.label}.plist";
  };

  envVars = {
    HOME = homeDir;
    PATH = paths.systemPath;
    XDG_CONFIG_HOME = config.xdg.configHome;
    COLIMA_HOME = paths.colimaConfigDir;
  };
in
{
  config = {
    home = {
      # Install all required packages
      packages = requiredPackages;

      # Install configuration files
      file = {
        "${paths.colimaConfigDir}/docker/colima.yaml".source = ./configs/docker.yaml;
        "${paths.colimaConfigDir}/k8s/colima.yaml".source = ./configs/k8s.yaml;
      };

      # Clean up previous installation
      activation.cleanupColima = lib.hm.dag.entryBefore [ "checkLaunchAgents" ] ''
        export PATH="${paths.systemPath}:$PATH"
        export XDG_CONFIG_HOME="${config.xdg.configHome}"
        export COLIMA_HOME="${paths.colimaConfigDir}"

        verboseEcho "Cleaning up Colima..."
        run "${paths.wrapperScript}" ${defaultProfile} clean
        run rm -f "/tmp/colima-${defaultProfile}.lock" || true
      '';

      # Add COLIMA_HOME to the shell environment
      sessionVariables = {
        COLIMA_HOME = paths.colimaConfigDir;
      };
    };

    launchd.agents.colima = {
      enable = true;
      config = {
        Label = agent.label;
        ProgramArguments = [
          "${paths.wrapperScript}"
          "${defaultProfile}"
          "daemon"
        ];
        EnvironmentVariables = envVars;
        RunAtLoad = true;
        WorkingDirectory = paths.currentProfileDir;
        StandardOutPath = "${paths.currentProfileDir}/colima.log";
        StandardErrorPath = "${paths.currentProfileDir}/colima.error.log";
        KeepAlive = {
          Crashed = true;
          SuccessfulExit = false;
        };
        ProcessType = "Interactive";
        ThrottleInterval = 30;
      };
    };

    programs.zsh.shellAliases =
      let
        mkColimaAlias = cmd: "colima ${cmd} -p";
      in
      {
        cstart = mkColimaAlias "start --save-config=false";
        cstop = mkColimaAlias "stop";
        cstatus = mkColimaAlias "status";
        cdelete = mkColimaAlias "delete";
        clist = "colima list";
        clog = "tail -f ${paths.currentProfileDir}/colima.log";
        clogerr = "tail -f ${paths.currentProfileDir}/colima.error.log";
      };
  };
}
