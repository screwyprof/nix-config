{ config, lib, pkgs, ... }: {
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    fontconfig
    # user fonts
    (nerdfonts.override { 
      fonts = [ 
        "FiraCode" 
        "JetBrainsMono"
        "Meslo" 
      ]; 
    })
  ];
} 