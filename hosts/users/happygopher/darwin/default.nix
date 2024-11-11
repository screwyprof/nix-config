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
}
