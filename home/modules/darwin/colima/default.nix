{ config, lib, pkgs, ... }: {
  home = {
    packages = with pkgs; [
      colima
    ];

    activation.createColimaConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # First stop and unload the agent if it exists
      if [ -f ~/Library/LaunchAgents/com.github.colima.nix.plist ]; then
        $DRY_RUN_CMD /bin/launchctl bootout gui/$UID/com.github.colima.nix || true
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
          # Switch to default context before stopping
          ${pkgs.docker}/bin/docker context use default || true
          ${pkgs.colima}/bin/colima stop -f -p docker
          exit 0
        }
        
        trap cleanup SIGTERM SIGINT SIGQUIT

        # Ensure profile exists before starting
        if [ ! -f "$COLIMA_HOME/docker/colima.yaml" ]; then
          echo "Error: Docker profile config not found at $COLIMA_HOME/docker/colima.yaml"
          exit 1
        fi

        # Start Colima
        ${pkgs.colima}/bin/colima --very-verbose -p docker start


        # Check if it started successfully
        sleep 5

        if ! ${pkgs.colima}/bin/colima status -p docker; then
          echo "Failed to start Colima"
          exit 1
        fi

        # Keep the process running to handle signals
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
        COLIMA_HOME = "${config.home.homeDirectory}/.colima";
        PATH = lib.concatStringsSep ":" [
          "/usr/bin"
          "/usr/sbin"
          "${pkgs.coreutils}/bin"
          "${pkgs.docker}/bin"
          "${pkgs.colima}/bin"
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
      cstart = "colima start -p docker";
      cstop = "colima stop -p docker";
      cstatus = "colima status -p docker";
      cdelete = "colima delete -p";
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
      # More robust Docker context handling
      if command -v docker >/dev/null 2>&1; then
        if [ -S "$HOME/.colima/docker/docker.sock" ] && docker info >/dev/null 2>&1; then
          docker context use colima-docker >/dev/null 2>&1
        fi
      fi
    '';
  };
}
