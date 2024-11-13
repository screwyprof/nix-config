{ config, lib, pkgs, ... }:

let
  defaultProfile = "docker";
in
{
  home = {
    packages = with pkgs; [
      colima
    ];

    file.".local/bin/colima-wrapper.sh" = {
      executable = true;
      source = ./scripts/colima-wrapper.sh;
    };

    # Create actual config files, not nix symlinks
    activation.copyColimaConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Case 1: Fresh system - nothing to clean
      # Case 2 & 3: Existing colima needs cleanup
      # Case 4: Running agent without colima needs cleanup

      # Check and stop agent if running
      if /bin/launchctl list | grep -q "com.github.colima.nix"; then
        echo "Stopping existing Colima agent..."
        $DRY_RUN_CMD /bin/launchctl bootout gui/$UID/com.github.colima.nix || true
        
        # Wait for agent to fully unload
        for i in $(seq 1 10); do
          if ! /bin/launchctl list | grep -q "com.github.colima.nix"; then
            break
          fi
          echo "Waiting for agent to unload... ($i/10)"
          sleep 1
        done
      fi

      # Check and stop colima if running
      if ${pkgs.colima}/bin/colima status >/dev/null 2>&1; then
        echo "Stopping running Colima instance..."
        $DRY_RUN_CMD ${pkgs.colima}/bin/colima stop -f || true
      fi

      # Clean up colima directory if exists
      if [ -n "${config.home.homeDirectory}/.colima" ] && [ -d "${config.home.homeDirectory}/.colima" ]; then
        echo "Cleaning up Colima state..."
        $DRY_RUN_CMD rm -rf "${config.home.homeDirectory}/.colima"
      fi

      # Create fresh config
      echo "Creating fresh Colima config..."
      $DRY_RUN_CMD mkdir -p ~/.colima/docker ~/.colima/k8s
      
      $DRY_RUN_CMD cp ${./configs/docker.yaml} ~/.colima/docker/colima.yaml
      $DRY_RUN_CMD chmod 644 ~/.colima/docker/colima.yaml
      
      $DRY_RUN_CMD cp ${./configs/k8s.yaml} ~/.colima/k8s/colima.yaml
      $DRY_RUN_CMD chmod 644 ~/.colima/k8s/colima.yaml
    '';
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
      cstart = "colima start -p";
      cstop = "colima stop -p";
      cstatus = "colima status -p";
      cdelete = "colima delete -p";
      clist = "colima list";
      clog = "tail -f ~/.colima/colima.log";
      clogerr = "tail -f ~/.colima/colima.error.log";
    };
  };
}
