{ lib, pkgs, ... }: {
  imports = [
    ./preferences
    ./terminal
    ./iterm2
    ../../../modules/shared
    ../../../modules/darwin/brew
    ../../../modules/darwin/coredumps
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

  xdg.enable = true;
}
