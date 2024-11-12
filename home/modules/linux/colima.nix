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
      vmType: qemu         # Different for Linux
      arch: x86_64         # Assuming x86_64 for Linux
      mountType: 9p        # Different for Linux
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

  # Linux uses systemd instead of launchd
  systemd.user.services.colima = {
    Unit = {
      Description = "Colima Docker VM";
      Requires = [ "network-online.target" ];
      After = [ "network-online.target" ];
    };

    Service = {
      Type = "forking";
      ExecStart = "${pkgs.colima}/bin/colima start";
      ExecStop = "${pkgs.colima}/bin/colima stop";
      Environment = "HOME=${config.home.homeDirectory}";
    };

    Install = {
      WantedBy = [ "default.target" ];
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
