{ config, lib, pkgs, ... }: {
  home = {
    packages = with pkgs; [
      colima
    ];

    file.".colima/default/colima.yaml".text = ''
      # CPU configuration
      cpu: 4
      memory: 16
      disk: 100
      
      # VM configuration
      vmType: vz
      arch: aarch64
      rosetta: true
      mountType: virtiofs
      mountInotify: true
      
      # Kubernetes configuration
      kubernetes:
        enabled: true
        version: v1.31.2+k3s1
        k3sArgs:
          - --disable=traefik
      
      # Docker configuration
      runtime: docker
      autoActivate: false
    '';

    activation.createColimaDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ${config.home.homeDirectory}/.colima
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
          # Start Colima
          ${pkgs.colima}/bin/colima --verbose start
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
      cstart = "colima start";
      cstop = "colima stop";
      cstatus = "colima status";
      cdelete = "colima delete";
      clog = "bat -f ~/.colima/colima.log";
      clogerr = "bat -f ~/.colima/colima.error.log";
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
