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
        onChange = ''
          echo "Colima wrapper updated!"
          ${pkgs.shellcheck}/bin/shellcheck "$HOME/.local/bin/colima-wrapper.sh" || true
        '';
      };
    };

    activation = {
      cleanupColima = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        # Set up PATH
        export PATH="${lib.makeBinPath [
          pkgs.coreutils
          pkgs.findutils
          pkgs.colima
          pkgs.docker
        ]}:/usr/bin:/usr/sbin:$PATH"

        echo "Checking initial state..."
        ${config.home.homeDirectory}/.local/bin/colima-wrapper.sh ${defaultProfile} status

        echo "Unloading existing Colima agent..."
        /bin/launchctl bootout gui/$UID ~/Library/LaunchAgents/org.nix-community.home.colima.plist 2>/dev/null || true

        # Clean up any remaining agent files
        rm -f ~/Library/LaunchAgents/org.nix-community.home.colima.plist || true

        echo "Cleaning up Colima..."
        ${config.home.homeDirectory}/.local/bin/colima-wrapper.sh ${defaultProfile} clean

        echo "Checking post-cleanup state..."
        ${config.home.homeDirectory}/.local/bin/colima-wrapper.sh ${defaultProfile} status
      '';
    };
  };

  launchd.agents.colima = {
    enable = true;
    config = {
      Label = "org.nix-community.home.colima";
      ProgramArguments = [
        "${config.home.homeDirectory}/.local/bin/colima-wrapper.sh"
        "${defaultProfile}"
        "daemon"
      ];
      RunAtLoad = true;
      StandardOutPath = "${config.home.homeDirectory}/.colima/docker/colima.log";
      StandardErrorPath = "${config.home.homeDirectory}/.colima/docker/colima.error.log";
      EnvironmentVariables = {
        HOME = "${config.home.homeDirectory}";
        COLIMA_HOME = "${config.home.homeDirectory}/.colima";
        COLIMA_PROFILE = defaultProfile;
        PATH = lib.concatStringsSep ":" [
          "${pkgs.coreutils}/bin"
          "${pkgs.docker}/bin"
          "${pkgs.colima}/bin"
          "/usr/bin"
          "/usr/sbin"
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
    clog = "tail -f ~/.colima/docker/colima.log";
    clogerr = "tail -f ~/.colima/docker/colima.error.log";
  };
}
