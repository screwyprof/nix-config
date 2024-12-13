{
  imports = [ ./ansi.nix ]; # Import ANSI color configuration

  home = {
    sessionVariables = {
      LS_COLORS = "di=34:ln=35:so=32:pi=33:ex=31:bd=36:cd=33:su=31:sg=36:tw=32:ow=33";
    };
  };

  xdg.configFile."fsh/dracula.ini".source = ./fsh.ini;

  programs.zsh = {
    sessionVariables = {
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=13";
    };

    zimfw = {
      initAfterZim = ''
        fast-theme "XDG:dracula" &>/dev/null || true
      '';
    };
  };
}
