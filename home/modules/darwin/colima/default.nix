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

      # Set COLIMA_HOME for interactive shells
      sessionVariables = {
        COLIMA_HOME = paths.colimaConfigDir;
      };

      file = {
        # This creates a "GC Root" by putting a symlink in the Nix Profile.
        # Nix GC will now see these files as 'in use' by your current profile.
        "${config.xdg.cacheHome}/colima/pins/docker.yaml.src".source = ./configs/docker.yaml;
        "${config.xdg.cacheHome}/colima/pins/k8s.yaml.src".source = ./configs/k8s.yaml;
      };

      # Copy config files (activation script)
      # Colima can't work with symlinked configs...
      activation.copyColimaConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p ${paths.colimaConfigDir}/docker ${paths.colimaConfigDir}/k8s
        
        # Copy function to handle store-to-mutable transitions
        copy_config() {
          local src="$1"
          local dest="$2"
          # Only copy if different or missing to avoid unnecessary writes
          if ! cmp -s "$src" "$dest"; then
            cp -f "$src" "$dest"
            chmod u+w "$dest"
          fi
        }

        run copy_config "${./configs/docker.yaml}" "${paths.colimaConfigDir}/docker/colima.yaml"
        run copy_config "${./configs/k8s.yaml}" "${paths.colimaConfigDir}/k8s/colima.yaml"
      '';
    };

    # Configure launchd agent
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
        mkColimaAlias = cmd: "colima ${cmd} -p ${defaultProfile}";
      in
      {
        cstart = mkColimaAlias "start --save-config=false";
        cstop = mkColimaAlias "stop";
        cstatus = mkColimaAlias "status";
        cdelete = mkColimaAlias "delete";
        clist = "colima list";
        clog = "tail -f ${paths.currentProfileDir}/colima.log";
        clogerr = "tail -f ${paths.currentProfileDir}/colima.error.log";

        # Convenience aliases that work without profile names
        colima-status = mkColimaAlias "status";
        colima-start = mkColimaAlias "start --save-config=false";
        colima-stop = mkColimaAlias "stop";
        colima-restart = "cstop && sleep 2 && cstart";
      };
  };
}
