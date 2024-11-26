{ config, lib, pkgs, ... }: {
  imports = [
    ./preferences
    ./terminal
    ./iterm2
    ../../../modules/shared
    ../../../modules/darwin/coredumps
    ../../../modules/darwin/colima
  ];

  # User-specific theme configuration
  theme = {
    name = "dracula";
    spec = "base24";
  };

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

  xdg = {
    enable = true;
    dataHome = "${config.home.homeDirectory}/.local/share";
    cacheHome = "${config.home.homeDirectory}/.cache";
  };
}
