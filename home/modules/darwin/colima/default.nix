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
      activation.cleanupColima = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        export PATH="${paths.systemPath}:$PATH"

        if /bin/launchctl list "${agent.label}" >/dev/null 2>&1; then
          verboseEcho "Colima agent exists, removing..."
          run /bin/launchctl bootout gui/$UID "${agent.plist}" 2>/dev/null || true
          run /bin/launchctl remove "${agent.label}" 2>/dev/null || true
        else
          verboseEcho "No existing colima agent found"
        fi

        verboseEcho "Cleaning up Colima..."
        run "${paths.wrapperScript}" ${defaultProfile} clean
      '';

      # Ensure the agent is loaded after setup
      activation.setupColimaAgent = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        verboseEcho "Starting Colima..."
        run /bin/launchctl bootstrap gui/$UID "${agent.plist}" || {
          errorEcho "Failed to bootstrap agent"
        }

        run /bin/launchctl kickstart -k "${agent.plist}"
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
        cstart = mkColimaAlias "start";
        cstop = mkColimaAlias "stop";
        cstatus = mkColimaAlias "status";
        cdelete = mkColimaAlias "delete";
        clist = "colima list";
        clog = "tail -f ${paths.profileDir}/colima.log";
        clogerr = "tail -f ${paths.profileDir}/colima.error.log";
      };
  };
}
