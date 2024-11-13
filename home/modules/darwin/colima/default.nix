{ config, lib, pkgs, ... }:

let
  defaultProfile = "docker";
in
{
  home = {
    packages = with pkgs; [
      colima
      shellcheck
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
        # Set up PATH to include GNU coreutils first
        export PATH="${lib.makeBinPath [
          pkgs.coreutils    # Make sure GNU coreutils comes first
          pkgs.findutils    # GNU find
          pkgs.colima
          pkgs.docker
        ]}:/usr/bin:/usr/sbin:$PATH"

        echo "Checking initial state..."
        ${config.home.homeDirectory}/.local/bin/colima-wrapper.sh ${defaultProfile} status

        echo "Cleaning up Colima..."
        ${config.home.homeDirectory}/.local/bin/colima-wrapper.sh ${defaultProfile} clean

        echo "Checking post-cleanup state..."
        ${config.home.homeDirectory}/.local/bin/colima-wrapper.sh ${defaultProfile} status
      '';

      loadColimaAgent = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # Set up PATH to include GNU coreutils first
        export PATH="${lib.makeBinPath [
          pkgs.coreutils    # Make sure GNU coreutils comes first
          pkgs.findutils    # GNU find
          pkgs.colima
          pkgs.docker
        ]}:/usr/bin:/usr/sbin:$PATH"
        
        if [ -f ~/Library/LaunchAgents/com.github.colima.nix.plist ]; then
          echo "Loading Colima agent..."
          /bin/launchctl bootstrap gui/$UID ~/Library/LaunchAgents/com.github.colima.nix.plist || true
         
         echo "Checking state after loading agent..."
         ${config.home.homeDirectory}/.local/bin/colima-wrapper.sh ${defaultProfile} status
        fi

        echo "Checking final state..."
        ${config.home.homeDirectory}/.local/bin/colima-wrapper.sh ${defaultProfile} status
      '';
    };
  };

  launchd.agents.colima = {
    enable = true;
    config = {
      Label = "com.github.colima.nix";
      ProgramArguments = [
        "${config.home.homeDirectory}/.local/bin/colima-wrapper.sh"
        "${defaultProfile}"
        "daemon"
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
