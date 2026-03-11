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
          diff = "batdiff";
          rg = "rg --hidden --glob '!.git'";
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
