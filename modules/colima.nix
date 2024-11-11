{ config, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    colima
    docker
  ];

  # User-specific Colima config
  home.file.".colima/default/colima.yaml".text = ''
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
    
    # Network configuration
    network:
      address: false
      dns: []
      dnsHosts: {}
      hostAddresses: false
    
    # Advanced settings
    forwardAgent: false
    docker: {}
    sshConfig: true
    sshPort: 0
    mounts: []
    env: {}
  '';

  # Create required directories
  home.activation.createColimaDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${config.home.homeDirectory}/.colima
  '';

  programs.zsh = {
    shellAliases = {
      cstart = "colima start";
      cstop = "colima stop";
      cstatus = "colima status";
      cdelete = "colima delete";
      clog = "bat -f ~/.colima/colima.log --style=plain";
      clogerr = "bat -f ~/.colima/colima.error.log --style=plain";
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
