{ pkgs, ... }: {
  home.packages = with pkgs; [
    moar
  ];

  programs.zsh = {
    initExtra = ''
      # Set moar as the default pager with all options
      export PAGER="${pkgs.moar}/bin/moar"
      export MOAR="\
        --style=dracula \
        --wrap \
        --statusbar=bold \
        --colors=16m \
        --quit-if-one-screen \
        --no-clear-on-exit \
        --mousemode=scroll"
    '';

    shellAliases = {
      more = "${pkgs.moar}/bin/moar";
      less = "${pkgs.moar}/bin/moar";
    };
  };
}
