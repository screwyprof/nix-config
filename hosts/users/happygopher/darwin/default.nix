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
          echo "Docker location: $(${pkgs.which}/bin/which docker)" >> ${config.home.homeDirectory}/.colima/colima.log
          echo "Colima location: $(${pkgs.which}/bin/which colima)" >> ${config.home.homeDirectory}/.colima/colima.log
          echo "sw_vers location: $(${pkgs.which}/bin/which sw_vers)" >> ${config.home.homeDirectory}/.colima/colima.log
          echo "==================" >> ${config.home.homeDirectory}/.colima/colima.log
          ${pkgs.colima}/bin/colima start
        ''
      ];
      RunAtLoad = true;
      StandardOutPath = "${config.home.homeDirectory}/.colima/colima.log";
      StandardErrorPath = "${config.home.homeDirectory}/.colima/colima.error.log";
      EnvironmentVariables = {
        HOME = "${config.home.homeDirectory}";
        PATH = lib.makeBinPath [
          pkgs.docker
          pkgs.coreutils
          pkgs.which
          "/usr/bin"
        ];
      };
    };
  };
}
