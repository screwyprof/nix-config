{ config, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    colima
    docker
  ];

  # Colima config file
  xdg.configFile."colima/default.yaml".text = ''
    # CPU configuration
    cpu: 4
    # Memory configuration (in GiB)
    memory: 8
    # Disk configuration (in GiB)
    disk: 100
    
    # VM configuration
    vmType: "vz"
    arch: "aarch64"
    
    # Docker configuration
    docker:
      enabled: true
      socket: "${config.home.homeDirectory}/.colima/default/docker.sock"
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
