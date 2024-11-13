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
      $DRY_RUN_CMD mkdir -p ~/.colima/docker ~/.colima/k8s
      
      $DRY_RUN_CMD rm -f ~/.colima/docker/colima.yaml
      $DRY_RUN_CMD cp ${./configs/docker.yaml} ~/.colima/docker/colima.yaml
      $DRY_RUN_CMD chmod 644 ~/.colima/docker/colima.yaml
      
      $DRY_RUN_CMD rm -f ~/.colima/k8s/colima.yaml
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
