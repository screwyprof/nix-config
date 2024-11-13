{ config, lib, pkgs, ... }:

let
  defaultProfile = "docker";
  
  # Helper to create profile configs
  mkProfileConfig = profile: {
    ".colima/${profile}/colima.yaml" = {
      text = builtins.readFile ./configs/${profile}.yaml;
      onChange = ''
        if /bin/launchctl list | grep -q "com.github.colima.nix"; then
          /bin/launchctl bootout gui/$UID/com.github.colima.nix || true
        fi
        rm -rf ~/.colima/${profile}/*
      '';
    };
  };
in
{
  home = {
    packages = with pkgs; [
      colima
    ];

    file = lib.mkMerge [
      (mkProfileConfig "docker")
      (mkProfileConfig "k8s")
      {
        ".local/bin/colima-wrapper.sh" = {
          executable = true;
          source = ./scripts/colima-wrapper.sh;
        };
      }
    ];
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
