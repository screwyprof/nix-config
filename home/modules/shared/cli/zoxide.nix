{ lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    fzf
    zoxide
    zim-plugins
  ];

  programs.zsh.zimfw.zmodules = lib.mkOrder 300 [
    "${pkgs.zim-plugins}/share/zsh/plugins/zim-plugins --source zoxide.zsh"
  ];
}
