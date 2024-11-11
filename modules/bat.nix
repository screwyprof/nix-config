{ pkgs, ... }: {
  programs.bat = {
    enable = true;
    config = {
      theme = "Dracula";
      style = "numbers,changes,header";
      pager = "moar";
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
    prettybat
  ];

  programs.zsh.shellAliases = {
    # Plain output, no pager, auto-detects pipes
    cat = "bat --plain --paging=never";
    
    # Rich output, using system pager (moar)
    bcat = "bat --style=numbers,changes,header";
    
    # Other aliases
    man = "${pkgs.bat-extras.batman}/bin/batman";
    diff = "${pkgs.bat-extras.batdiff}/bin/batdiff";
    rg = "${pkgs.ripgrep}/bin/rg --hidden --glob '!.git'";
    history = "history | awk '{$1=\"\"; print substr($0,2)}' | bat --style=plain --language=bash";

    # Bat-extras aliases
    batdiff = "${pkgs.bat-extras.batdiff}/bin/batdiff";
    batgrep = "${pkgs.bat-extras.batgrep}/bin/batgrep";
    batman = "${pkgs.bat-extras.batman}/bin/batman";
    prettybat = "${pkgs.bat-extras.prettybat}/bin/prettybat";
  };
}
