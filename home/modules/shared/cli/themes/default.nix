{ config, lib, pkgs, ... }:
let
  # Assert that a path exists or throw an error
  assertPath = path:
    assert builtins.pathExists path;
    path;
in
{
  home = {
    packages = [ pkgs.tinty ];
    file = {
      "${config.xdg.configHome}/zsh/colors.sh".source = assertPath ./zsh-dracula-ansi.sh;
      "${config.xdg.configHome}/fzf/colors.sh".source = assertPath ./fzf-dracula-ansi.sh;
      "${config.xdg.configHome}/eza/theme.yml".source = assertPath ./eza-dracula.yml;
    };

    sessionVariables = {
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=13";
    };
  };

  programs.zsh = {
    envExtra = lib.mkAfter ''
      # shell theme
      [ -f ~/.config/zsh/colors.sh ] && source ~/.config/zsh/colors.sh
      export LS_COLORS="di=34:ln=35:so=32:pi=33:ex=31:bd=36:cd=33:su=31:sg=36:tw=32:ow=33"

      # fzf theme
      #[ -f ~/.config/fzf/colors.sh ] && source ~/.config/fzf/colors.sh
    '';

    zimfw.zmodules = lib.mkOrder 400 [
      "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k --source powerlevel10k.zsh-theme"
      "${toString ../zsh/zim/plugins} --source p10k.zsh"
    ];
  };
}
