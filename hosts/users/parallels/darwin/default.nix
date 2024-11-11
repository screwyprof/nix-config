{ config, lib, pkgs, ... }: {
  imports = [
    ./terminal
    ./preferences
  ];

  home.homeDirectory = lib.mkForce "/Users/parallels";
  xdg.dataHome = "${config.home.homeDirectory}/.local/share";

  # Simple launchd configuration for Colima
  launchd.agents.colima = {
    enable = true;
    config = {
      Label = "com.github.colima";
      ProgramArguments = [
        "${pkgs.colima}/bin/colima"
        "start"
        "--runtime"
        "docker"
      ];
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "${config.home.homeDirectory}/.colima/colima.log";
      StandardErrorPath = "${config.home.homeDirectory}/.colima/colima.error.log";
      EnvironmentVariables = {
        HOME = "${config.home.homeDirectory}";
      };
    };
  };

  # Just ensure the required packages are installed
  home.packages = with pkgs; [
    colima
    docker
    docker-client
  ];
}
