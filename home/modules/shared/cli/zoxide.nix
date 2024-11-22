{ pkgs, ... }:
{
  home.packages = with pkgs; [
    fzf
    zoxide
  ];

  #programs.zoxide = {
  #enable = true;
  #enableZshIntegration = true;
  # options = [
  #   "--cmd cd" # Replace cd with z
  # ];
  #};
}
