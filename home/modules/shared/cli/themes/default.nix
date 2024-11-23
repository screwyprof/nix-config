{ config, lib, pkgs, ... }:
let
  theme = "base24-dracula";

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
      "${config.xdg.configHome}/bat/themes/${theme}.tmTheme".source = assertPath ./Gopher.tmTheme;
      "${config.xdg.configHome}/eza/theme.yml".source = ./eza-dracula.yml;
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

      # bat theme
      if [[ -f ~/.config/bat/themes/${theme}.tmTheme ]]; then
        export BAT_THEME="${theme}"
      fi
    '';

    initExtra = lib.mkAfter ''
      # bat theme
      # Only rebuild cache if the theme isn't in the themes list
      if ! bat --list-themes | grep -q "${theme}"; then
        bat cache --build >/dev/null 2>&1
      fi
    '';
  };
}
