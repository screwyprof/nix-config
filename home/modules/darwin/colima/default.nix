{ config, lib, pkgs, ... }: {
  home = {
    packages = with pkgs; [
      colima
    ];

    activation.createColimaConfigs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Create directories
      $DRY_RUN_CMD mkdir -p ~/.colima

      # Docker profile
      rm -rf ~/.colima/docker.yaml
      $DRY_RUN_CMD cat ${./configs/docker.yaml} > ~/.colima/docker.yaml

      # K8s profile
      rm -rf ~/.colima/k8s.yaml
      $DRY_RUN_CMD cat ${./configs/k8s.yaml} > ~/.colima/k8s.yaml

      # Set proper permissions
      $DRY_RUN_CMD chmod 644 ~/.colima/docker.yaml ~/.colima/k8s.yaml
    '';
  };

  launchd.agents.colima = {
    enable = true;
    config = {
      Label = "com.github.colima.nix";
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          # Start Colima with default profile (Docker only)
          ${pkgs.colima}/bin/colima --verbose -p docker start
        ''
      ];
      RunAtLoad = true;
      StandardOutPath = "${config.home.homeDirectory}/.colima/colima.log";
      StandardErrorPath = "${config.home.homeDirectory}/.colima/colima.error.log";
      EnvironmentVariables = {
        HOME = "${config.home.homeDirectory}";
        PATH = lib.makeBinPath [
          "/usr"
          pkgs.coreutils
          pkgs.which
          pkgs.docker
          pkgs.colima
        ];
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