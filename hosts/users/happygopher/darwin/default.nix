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
          # Stop and delete if exists
          ${pkgs.colima}/bin/colima stop || true
          ${pkgs.colima}/bin/colima delete -f|| true

          # Start Colima
          ${pkgs.colima}/bin/colima --verbose start
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
