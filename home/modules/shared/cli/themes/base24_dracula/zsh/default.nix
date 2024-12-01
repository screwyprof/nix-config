{ lib, pkgs, ... }:
{
  home = {
    sessionVariables = {
      LS_COLORS = "di=34:ln=35:so=32:pi=33:ex=31:bd=36:cd=33:su=31:sg=36:tw=32:ow=33";
    };
  };

  xdg.configFile."fsh/dracula.ini".source = ./fsh-dracula.ini;

  programs.zsh = {
    sessionVariables = {
      FAST_WORK_DIR = "$XDG_CONFIG_HOME/fsh";
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=13";
    };

    zimfw.zmodules = lib.mkOrder 400 [
      "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k --source powerlevel10k.zsh-theme"
      "${toString ./.} --source p10k.zsh"
      "${toString ./.} --source zsh-dracula-ansi.sh"
    ];
  };
}
