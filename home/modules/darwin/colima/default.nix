{ config, lib, pkgs, ... }:

let
  # Basic configuration
  defaultProfile = "docker";
  homeDir = config.home.homeDirectory;

  # Required packages for the PATH
  requiredPackages = with pkgs; [
    coreutils
    findutils
    flock
    bash
    docker
    colima
  ];

  # Create the wrapper script
  wrapperScript = pkgs.writeScriptBin "colima-wrapper.sh" (builtins.readFile ./scripts/colima-wrapper.sh);

  paths = {
    profileDir = "${homeDir}/.colima/${defaultProfile}";
    configDir = "${homeDir}/.colima";
    wrapperScript = lib.getExe wrapperScript;
    systemPath = lib.makeBinPath requiredPackages + ":/usr/bin:/usr/sbin:/bin:/sbin";
  };

  agent = {
    label = "org.nix-community.home.colima";
    plist = "${homeDir}/Library/LaunchAgents/${agent.label}.plist";
  };

  envVars = {
    HOME = homeDir;
    COLIMA_HOME = paths.configDir;
    COLIMA_PROFILE = defaultProfile;
    COLIMA_LOG_ROTATE = "true";
    COLIMA_LOG_SIZE = "10M";
    PATH = paths.systemPath;
  };
in
{
  config = {
    home = {
      packages = [ pkgs.colima wrapperScript ];

      # File management
      file = {
        ".colima/docker/colima.yaml".source = ./configs/docker.yaml;
        ".colima/k8s/colima.yaml".source = ./configs/k8s.yaml;
      };

      # Activation script
      activation.cleanupColima = lib.hm.dag.entryBefore [ "setupLaunchAgents" ] ''
        export PATH="${paths.systemPath}:$PATH"

        # Clean stale lock file
        rm -f "/tmp/colima-${defaultProfile}.lock" || true

        verboseEcho "Cleaning up Colima..."
        run "${paths.wrapperScript}" ${defaultProfile} clean
      '';
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
        EnvironmentVariables = envVars;
        RunAtLoad = true;
        WorkingDirectory = paths.configDir;
        StandardOutPath = "${paths.profileDir}/colima.log";
        StandardErrorPath = "${paths.profileDir}/colima.error.log";
        KeepAlive = {
          Crashed = true;
          SuccessfulExit = false;
        };
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
        clog = "tail -f ~/.colima/${defaultProfile}/colima.log";
        clogerr = "tail -f ~/.colima/${defaultProfile}/colima.error.log";
      };

    # Add debug output
    home.activation.debugLaunchd = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "Debug: LaunchAgents config:"
      echo "Enable: ${toString config.launchd.agents.colima.enable}"
      echo "Label: ${config.launchd.agents.colima.config.Label}"
      echo "Plist path: ${agent.plist}"
    '';
  };
}
