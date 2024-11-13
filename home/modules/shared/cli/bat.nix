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

  programs.zsh {
  shellAliases = {
    # Plain cat replacement (no styling, no paging)
    cat = "bat --plain --paging=never";

    # Last 80 lines of history, newest first
    history = "history 0 | tail -n 80 | tac | awk '{$1=\"\"; print substr($0,2)}' | bat --file-name 'Shell History' --language=bash";

    # Other aliases
    diff = "${pkgs.bat-extras.batdiff}/bin/batdiff";
    rg = "${pkgs.ripgrep}/bin/rg --hidden --glob '!.git'";

    # Bat-extras aliases
    batdiff = "${pkgs.bat-extras.batdiff}/bin/batdiff";
    batgrep = "${pkgs.bat-extras.batgrep}/bin/batgrep";
    batman = "${pkgs.bat-extras.batman}/bin/batman";
    prettybat = "${pkgs.bat-extras.prettybat}/bin/prettybat";
  };

  initBatFunctions = ''
    # Enhanced tail -f with bat
    tail() {
      if [[ "$1" == "-f" ]]; then
        command tail "$@" | bat --paging=never -l log
      else
        command tail "$@"
      fi
    }
  '';
}

}
