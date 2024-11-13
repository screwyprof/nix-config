{ config, lib, pkgs, ... }:

let
  defaultProfile = "docker";
in
{
  home = {
    packages = with pkgs; [
      colima
    ];

    file = {
      ".colima/docker/colima.yaml".source = ./configs/docker.yaml;
      ".colima/k8s/colima.yaml".source = ./configs/k8s.yaml;
      ".local/bin/colima-wrapper.sh" = {
        executable = true;
        source = ./scripts/colima-wrapper.sh;
      };
    };

    activation = {
      cleanupColima = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        echo "Cleaning up Colima..."
        ${config.home.homeDirectory}/.local/bin/colima-wrapper.sh ${defaultProfile} clean
      '';

      loadColimaAgent = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -f ~/Library/LaunchAgents/com.github.colima.nix.plist ]; then
          echo "Loading Colima agent..."
          /bin/launchctl bootstrap gui/$UID ~/Library/LaunchAgents/com.github.colima.nix.plist || true
        fi
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

  programs.zsh.shellAliases = {
    cstart = "colima start -p";
    cstop = "colima stop -p";
    cstatus = "colima status -p";
    cdelete = "colima delete -p";
    clist = "colima list";
    clog = "tail -f ~/.colima/colima.log";
    clogerr = "tail -f ~/.colima/colima.error.log";
  };
}
