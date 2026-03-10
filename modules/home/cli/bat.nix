{
  flake.modules.homeManager.cli-bat =
    { lib, pkgs, ... }:
    {
      programs.bat = {
        enable = true;
        config = {
          style = "numbers,changes,header";
          pager = "moor";
          map-syntax = [
            "*.vim:VimL"
            ".vimrc:VimL"
            "*vimrc:VimL"
            "*-vimrc:VimL"
          ];
        };
      };

      home.packages = with pkgs.bat-extras; [
        batdiff
        batgrep
        batman
        prettybat
      ];

      programs.zsh = {
        shellAliases = {
          cat = "bat --plain --paging=never";
          history = "history 0 | tail -n 80 | tac | awk '{$1=\"\"; print substr($0,2)}' | bat --file-name 'Shell History' --language=bash";
          diff = "${pkgs.bat-extras.batdiff}/bin/batdiff";
          rg = "${pkgs.ripgrep}/bin/rg --hidden --glob '!.git'";
          batdiff = "${pkgs.bat-extras.batdiff}/bin/batdiff";
          batgrep = "${pkgs.bat-extras.batgrep}/bin/batgrep";
          batman = "${pkgs.bat-extras.batman}/bin/batman";
          prettybat = "${pkgs.bat-extras.prettybat}/bin/prettybat";
        };

        initContent = lib.mkAfter ''
          # Enhanced tail -f with bat
          tail() {
            if [[ "$1" == "-f" ]]; then
              command tail "$@" | bat --paging=never -l log
            else
              command tail "$@"
            fi
          }
        '';
      };
    };
}
