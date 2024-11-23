{ pkgs, ... }: {
  home.packages = with pkgs; [
    moar
  ];

  programs.zsh = {
    sessionVariables = {
      PAGER = "${pkgs.moar}/bin/moar";
      MOAR = ''
        --style=dracula \
        --wrap \
        --statusbar=bold \
        --colors=16m \
        --quit-if-one-screen \
        --no-clear-on-exit \
        --mousemode=auto \
        --no-linenumbers
      '';
    };

    shellAliases = {
      more = "${pkgs.moar}/bin/moar";
      less = "${pkgs.moar}/bin/moar";
    };
  };
}
