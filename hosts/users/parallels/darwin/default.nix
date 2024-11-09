{ config, lib, pkgs, ... }: {
  imports = [
    ./terminal
    ./preferences
  ];

  home.homeDirectory = lib.mkForce "/Users/parallels";

  home.packages = with pkgs; [
    mysides
  ];

  # This will create the fonts in ~/.local/share/fonts
  xdg.dataHome = "${config.home.homeDirectory}/.local/share";
}