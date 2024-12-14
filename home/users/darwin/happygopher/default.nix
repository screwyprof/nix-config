{ config, pkgs, ... }: {
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
    stateVersion = "24.11";

    file = {
      "Projects".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Documents/Projects";
    };

    # Darwin-specific packages
    packages = with pkgs; [
      mysides
    ];
  };

  xdg.enable = true;
}
