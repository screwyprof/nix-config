{ config, lib, pkgs, ... }:
let
  cheatsheets = pkgs.fetchFromGitHub {
    owner = "cheat";
    repo = "cheatsheets";
    rev = "master";
    sha256 = "sha256-Afv0rPlYTCsyWvYx8UObKs6Me8IOH5Cv5u4fO38J8ns=";
  };
in
{
  home = {
    packages = [ pkgs.cheat ];

    file = {
      ".config/cheat/conf.yml".text = ''
        editor: vim
        colorize: true
        style: dracula
        cheatpaths:
          - name: personal
            path: ~/.config/cheat/cheatsheets
            tags: [ personal ]
            readonly: false

          - name: community
            path: ${cheatsheets}
            tags: [ community ]
            readonly: true
      '';

      ".config/cheat/cheatsheets/.keep".text = "";
    };
  };
}
