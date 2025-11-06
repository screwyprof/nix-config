{ pkgs, ... }: {
  home = {
    packages = with pkgs; [
      moor
    ];

    sessionVariables = {
      PAGER = "${pkgs.moor}/bin/moor";
      MOOR = ''
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
  };

  programs.zsh = {
    shellAliases = {
      more = "${pkgs.moor}/bin/moor";
      less = "${pkgs.moor}/bin/moor";
    };
  };
}
