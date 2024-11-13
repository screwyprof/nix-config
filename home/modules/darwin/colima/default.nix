{ config, lib, pkgs, ... }: {
  home = {
    packages = with pkgs; [
      colima
    ];

    activation.createColimaConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # First stop and unload the agent if it exists
      if [ -f ~/Library/LaunchAgents/com.github.colima.nix.plist ]; then
        $DRY_RUN_CMD launchctl unload ~/Library/LaunchAgents/com.github.colima.nix.plist || true
      fi

      # Create directories
      $DRY_RUN_CMD mkdir -p ~/.colima/docker ~/.colima/k8s

      # Docker profile
      rm -rf ~/.colima/docker/colima.yaml
      $DRY_RUN_CMD cat ${./configs/docker.yaml} > ~/.colima/docker/colima.yaml

      # K8s profile
      rm -rf ~/.colima/k8s/colima.yaml
      $DRY_RUN_CMD cat ${./configs/k8s.yaml} > ~/.colima/k8s/colima.yaml

      # Set proper permissions
      $DRY_RUN_CMD chmod 644 ~/.colima/docker/colima.yaml ~/.colima/k8s/colima.yaml
    '';

    # Create a wrapper script for colima start/stop
    file.".local/bin/colima-wrapper.sh" = {
      executable = true;
      text = ''
        #!/bin/sh
        
        cleanup() {
          ${pkgs.colima}/bin/colima stop -p docker
          exit 0
        }
        
        trap cleanup SIGTERM SIGINT SIGQUIT
        
        ${pkgs.colima}/bin/colima --very-verbose -p docker start
        
        # Keep the script running to handle signals
        while true; do
          sleep 1
        done
      '';
    };
  };

  launchd.agents.colima = {
    enable = true;
    config = {
      Label = "com.github.colima.nix";
      ProgramArguments = [
        "${config.home.homeDirectory}/.local/bin/colima-wrapper.sh"
      ];
      RunAtLoad = true;
      StandardOutPath = "${config.home.homeDirectory}/.colima/colima.log";
      StandardErrorPath = "${config.home.homeDirectory}/.colima/colima.error.log";
      EnvironmentVariables = {
        HOME = "${config.home.homeDirectory}";
        PATH = lib.makeBinPath [
          "/usr"
          "/usr/sbin"
          pkgs.coreutils
          pkgs.which
          pkgs.docker
          pkgs.colima
        ];
        COLIMA_LOG_ROTATE = "true";
        COLIMA_LOG_SIZE = "10M";
      };
      KeepAlive = {
        Crashed = true;
        SuccessfulExit = false;
      };
      ThrottleInterval = 30;
    };
  };

  programs.zsh = {
    shellAliases = {
      # Default profile commands (Docker)
      cstart = "colima start";
      cstop = "colima stop";
      cstatus = "colima status";
      cdelete = "colima delete";
      clist = "colima list";
      clog = "bat -f ~/.colima/colima.log";
      clogerr = "bat -f ~/.colima/colima.error.log";

      # K8s profile commands
      ckstart = "colima start -p k8s";
      ckstop = "colima stop -p k8s";
      ckstatus = "colima status -p k8s";
      ckdelete = "colima delete -p k8s";
    };

    initExtra = ''
      # Set DOCKER_HOST when Colima is running
      if command -v colima >/dev/null 2>&1; then
        if colima status >/dev/null 2>&1; then
          export DOCKER_HOST="unix://${config.home.homeDirectory}/.colima/default/docker.sock"
        fi
      fi
    '';
  };
}
