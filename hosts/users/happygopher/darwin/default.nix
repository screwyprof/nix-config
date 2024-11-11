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
          echo "Docker location: $(which docker 2>&1)" >> ${config.home.homeDirectory}/.colima/colima.log
          echo "Colima location: $(which colima 2>&1)" >> ${config.home.homeDirectory}/.colima/colima.log
          echo "==================" >> ${config.home.homeDirectory}/.colima/colima.log
          
          exec ${pkgs.colima}/bin/colima start
        ''
      ];
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "${config.home.homeDirectory}/.colima/colima.log";
      StandardErrorPath = "${config.home.homeDirectory}/.colima/colima.error.log";
      EnvironmentVariables = {
        HOME = "${config.home.homeDirectory}";
        PATH = "${lib.makeBinPath [ pkgs.docker ]}:${config.environment.systemPath}";
      };
    };
  };
}
