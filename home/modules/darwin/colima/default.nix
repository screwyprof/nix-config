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
    logDir = "${homeDir}/.colima/${defaultProfile}";
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

        # Set verbose mode based on VERBOSE_ARG
        #[[ -n "$VERBOSE_ARG" ]] && export VERBOSE=1

        verboseEcho "Unloading existing Colima agent..."
        run /bin/launchctl bootout gui/$UID "${agent.plist}" 2>/dev/null || true
        run rm --verbose -f "${agent.plist}" || true

        verboseEcho "Cleaning up Colima..."
        run env "VERBOSE=''${VERBOSE:-}" "${paths.wrapperScript}" ${defaultProfile} clean
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
        StandardOutPath = "${paths.logDir}/colima.log";
        StandardErrorPath = "${paths.logDir}/colima.error.log";
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
  };
}
