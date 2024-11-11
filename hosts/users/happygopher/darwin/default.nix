{ config, lib, pkgs, ... }: {
  imports = [
    ./terminal
    ./preferences
  ];

  # Group all home settings together
  home = {
    username = lib.mkForce "happygopher";
    homeDirectory = lib.mkForce "/Users/happygopher";

    # Darwin-specific packages
    packages = with pkgs; [
      mysides
    ];
  };

  xdg.dataHome = "${config.home.homeDirectory}/.local/share";

  # Simple launchd configuration for Colima
  launchd.agents.colima = {
    enable = true;
    config = {
      Label = "com.github.colima.nix";
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          echo "=== Debug Info ===" >> ${config.home.homeDirectory}/.colima/colima.log
          echo "Date: $(date)" >> ${config.home.homeDirectory}/.colima/colima.log
          echo "PATH: $PATH" >> ${config.home.homeDirectory}/.colima/colima.log
          echo "Config file:" >> ${config.home.homeDirectory}/.colima/colima.log
          cat ${config.home.homeDirectory}/.colima/default/colima.yaml >> ${config.home.homeDirectory}/.colima/colima.log
          echo "==================" >> ${config.home.homeDirectory}/.colima/colima.log
          ${pkgs.colima}/bin/colima start 
          --verbose
          --config "${config.home.homeDirectory}/.colima/default/colima.yaml"
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
}
