{ pkgs, ... }: {
  programs.bat = {
    enable = true;
    config = {
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
    batpipe
    batwatch
    prettybat
  ];

  programs.zsh.shellAliases = {
    # Basic bat alias
    cat = "${pkgs.bat}/bin/bat";

    # Bat-extras aliases
    batdiff = "${pkgs.bat-extras.batdiff}/bin/batdiff";
    batgrep = "${pkgs.bat-extras.batgrep}/bin/batgrep";
    batman = "${pkgs.bat-extras.batman}/bin/batman";
    prettybat = "${pkgs.bat-extras.prettybat}/bin/prettybat";
  };
}
