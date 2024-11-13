{ config, lib, pkgs, ... }: {
  home = {
    packages = with pkgs; [
      colima
    ];

    # Default profile for Docker (lighter resources for regular development)
    file.".colima/docker/colima.yaml".text = ''
      cpu: 6         # Half of total cores (using mostly P-cores)
      memory: 16     # 25% of total RAM
      disk: 100
      
      vmType: vz
      arch: aarch64
      rosetta: true
      mountType: virtiofs
      mountInotify: true
      
      runtime: docker
      autoActivate: true
      
      # CPU configuration
      cpuType: host  # Use host CPU type for better performance
      kubernetes:
        enabled: false
    '';

    # K8s profile with more resources for container orchestration
    file.".colima/k8s/colima.yaml".text = ''
      cpu: 8         # Use more cores for k8s workloads
      memory: 32     # 50% of total RAM
      disk: 100
      
      vmType: vz
      arch: aarch64
      rosetta: true
      mountType: virtiofs
      mountInotify: true
      
      # CPU configuration
      cpuType: host
      
      kubernetes:
        enabled: true
        version: v1.31.2+k3s1
        k3sArgs:
          - --disable=traefik
      
      runtime: docker
      autoActivate: true
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
          ${pkgs.colima}/bin/colima --verbose -p k8s start
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
