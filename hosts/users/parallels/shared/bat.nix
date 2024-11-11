{ pkgs, ... }: {
  programs.bat = {
    enable = true;
    config = {
      pager = "moar";
      theme = "Dracula";
      style = "numbers,changes,header";
      map-syntax = [
        "*.vim:VimL"
        ".vimrc:VimL"
        "*vimrc:VimL"
        "*-vimrc:VimL"
      ];
    };
  };

  # Bat-extras packages
  home.packages = with pkgs.bat-extras; [
    batdiff
    batgrep
    batman
    #batpipe
    #batwatch
    prettybat
  ];

  programs.zsh.shellAliases = {
    # Basic bat alias
    cat = "${pkgs.bat}/bin/bat --color=always --style=plain";
    man = "${pkgs.bat-extras.batman}/bin/batman";
    diff = "${pkgs.bat-extras.batdiff}/bin/batdiff";
    rg = "${pkgs.ripgrep}/bin/rg --hidden --glob '!.git'";
    history = "history | awk '{$1=\"\"; print substr($0,2)}' | bat --color=always --style=plain --language=bash";

    # Bat-extras aliases
    batdiff = "${pkgs.bat-extras.batdiff}/bin/batdiff";
    batgrep = "${pkgs.bat-extras.batgrep}/bin/batgrep";
    batman = "${pkgs.bat-extras.batman}/bin/batman";
    prettybat = "${pkgs.bat-extras.prettybat}/bin/prettybat";
  };
}
