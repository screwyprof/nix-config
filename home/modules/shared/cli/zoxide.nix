{ lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    fzf
    zoxide
  ];

  programs.zsh.zimfw.zmodules = lib.mkOrder 300 [
    "${toString ./zsh/zim/plugins} --source zoxide.zsh"
  ];
}
