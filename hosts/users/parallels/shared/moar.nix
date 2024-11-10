{ pkgs, ... }: {
  home.packages = with pkgs; [
    moar
  ];

  programs.zsh = {
    initExtra = ''
      # Set moar as the default pager
      export PAGER="${pkgs.moar}/bin/moar"
      
      # Configure moar options
      export MOAR="\
        --style=dracula \
        --wrap \
        --statusbar=bold \
        --colors=16m \
        --quit-if-one-screen \
        --mousemode=scroll"  # Fixed mousemode option
    '';

    shellAliases = {
      more = "${pkgs.moar}/bin/moar";
      less = "${pkgs.moar}/bin/moar";
    };
  };
}
