{ config, lib, pkgs, ... }: {
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    # user fonts
    (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" ]; })
  ];
} 