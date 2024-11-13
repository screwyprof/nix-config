{ config, lib, pkgs, ... }:

let
  # Default profile configuration
  defaultProfile = "docker";
in
{
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

    file.".local/bin/colima-wrapper.sh" = {
      executable = true;
      text = ''
        #!/bin/sh
        
        PROFILE=''${COLIMA_PROFILE:-${defaultProfile}}
        
        cleanup() {
          ${pkgs.docker}/bin/docker context use default || true
          ${pkgs.colima}/bin/colima stop -f -p $PROFILE
          exit 0
        }
        
        trap cleanup SIGTERM SIGINT SIGQUIT

        # Ensure profile exists before starting
        if [ ! -f "$COLIMA_HOME/$PROFILE/colima.yaml" ]; then
          echo "Error: Profile config not found at $COLIMA_HOME/$PROFILE/colima.yaml"
          exit 1
        fi

        # Start Colima
        ${pkgs.colima}/bin/colima --verbose -p $PROFILE start

        # Check if it started successfully
        sleep 5

        if ! ${pkgs.colima}/bin/colima status -p $PROFILE; then
          echo "Failed to start Colima with profile $PROFILE"
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
        COLIMA_PROFILE = defaultProfile;
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
      # Profile-agnostic commands
      cstart = "colima start -p";
      cstop = "colima stop -p";
      cstatus = "colima status -p";
      cdelete = "colima delete -p";
      clist = "colima list";
      clog = "tail -f ~/.colima/colima.log | bat --paging=never -l log";
      clogerr = "tail -f ~/.colima/colima.error.log | bat --paging=never -l log";
    };

    initExtra = ''
      # More robust Docker context handling
      if command -v docker >/dev/null 2>&1; then
        if [ -S "$HOME/.colima/''${COLIMA_PROFILE:-${defaultProfile}}/docker.sock" ] && \
           docker info >/dev/null 2>&1; then
          docker context use colima-''${COLIMA_PROFILE:-${defaultProfile}} >/dev/null 2>&1
        fi
      fi
    '';
  };
}
