{ config, ... }:

let
  inherit (config.colorScheme) palette;
in
{
  imports = [ ./ansi.nix ]; # Import ANSI color configuration

  programs.zsh = {
    sessionVariables = {
      # Base colors
      ZSH_THEME_COLOR_BG = palette.base00;
      ZSH_THEME_COLOR_FG = palette.base05;
      ZSH_THEME_COLOR_SELECTION = palette.base02;
      ZSH_THEME_COLOR_HIGHLIGHT = palette.base03;
      ZSH_THEME_COLOR_COMMENT = palette.base03;
      ZSH_THEME_COLOR_RED = palette.base08;
      ZSH_THEME_COLOR_GREEN = palette.base0B;
      ZSH_THEME_COLOR_YELLOW = palette.base0A;
      ZSH_THEME_COLOR_BLUE = palette.base0D;
      ZSH_THEME_COLOR_MAGENTA = palette.base0E;
      ZSH_THEME_COLOR_CYAN = palette.base0C;

      # Git status colors
      ZSH_THEME_GIT_PROMPT_ADDED = "%F{${palette.base0B}}";
      ZSH_THEME_GIT_PROMPT_MODIFIED = "%F{${palette.base0A}}";
      ZSH_THEME_GIT_PROMPT_DELETED = "%F{${palette.base08}}";
      ZSH_THEME_GIT_PROMPT_RENAMED = "%F{${palette.base0E}}";
      ZSH_THEME_GIT_PROMPT_UNMERGED = "%F{${palette.base08}}";
      ZSH_THEME_GIT_PROMPT_UNTRACKED = "%F{${palette.base03}}";

      # Autosuggestions
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=13";
    };

    zimfw = {
      initAfterZim = ''
        fast-theme "forest" &>/dev/null || true
      '';
    };
  };
}
