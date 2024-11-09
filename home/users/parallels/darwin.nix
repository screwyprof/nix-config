{ config, lib, pkgs, ... }: {
  imports = [
    ./darwin/terminal
  ];

  home.homeDirectory = lib.mkForce "/Users/parallels";

  # This will create the fonts in ~/.local/share/fonts
  xdg.dataHome = "${config.home.homeDirectory}/.local/share";
}