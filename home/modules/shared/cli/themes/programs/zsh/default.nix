{ lib, pkgs, ... }:

{
  programs.zsh = {
    zimfw = {
      zmodules = lib.mkOrder 400 [
        "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k --source powerlevel10k.zsh-theme"
        "${toString ./.} --source p10k.zsh"
      ];
    };
  };
}
