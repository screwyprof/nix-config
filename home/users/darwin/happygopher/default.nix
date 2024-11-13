{ config, lib, pkgs, ... }: {
  imports = [
    ./terminal
    ./preferences
    ../../../modules/shared
    ../../../modules/darwin/colima
  ];

  # Group all home settings together
  home = {
    username = "happygopher";
    homeDirectory = lib.mkForce "/Users/happygopher";
    stateVersion = "24.05";

    # Darwin-specific packages
    packages = with pkgs; [
      mysides
    ];
  };

  xdg.dataHome = "${config.home.homeDirectory}/.local/share";
}
