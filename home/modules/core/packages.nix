{ pkgs, ... }: {
  fonts.fontconfig.enable = true;  # Enable font management

  home.packages = with pkgs; [
    # user fonts
    (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" ]; })

    # User-level tools
    mysides
    k9s
  ];
} 