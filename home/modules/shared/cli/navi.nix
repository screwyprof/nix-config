{ config, lib, pkgs, ... }:

let
  naviCheats = pkgs.fetchFromGitHub {
    owner = "denisidoro";
    repo = "cheats";
    rev = "master";
    sha256 = "sha256-wPsAazAGKPhu0MZfZbZ0POUBEMg95frClAQERTDFXUg=";
  };

  naviTLDR = pkgs.fetchFromGitHub {
    owner = "denisidoro";
    repo = "navi-tldr-pages";
    rev = "master";
    sha256 = "sha256-/w/0s0HpEHwyBoWD5uOLMJW1pbDFyOBvG4fKhmYPPp4=";
  };
in
{
  home = {
    packages = with pkgs; [
      navi
    ];

    sessionVariables = {
      NAVI_CONFIG = "${config.xdg.configHome}/navi/config.yaml";
    };

    file."${config.xdg.dataHome}/navi/cheats/denisidoro__cheats".source = naviCheats;
    file."${config.xdg.dataHome}/navi/cheats/denisidoro__navi-tldr-pages".source = naviTLDR;
  };

  xdg.configFile."navi/config.yaml".text = lib.generators.toYAML { } {
    cheats = {
      paths = [
        "${config.xdg.dataHome}/navi/cheats"
        "${config.xdg.dataHome}/navi/cheats/denisidoro__cheats"
        "${config.xdg.dataHome}/navi/cheats/denisidoro__navi-tldr-pages"
      ];
    };

    finder = {
      command = "fzf";
    };

    client = {
      tealdeer = true;
    };

    shell = {
      command = "zsh";
    };
  };

  programs.zsh.zimfw.zmodules = lib.mkOrder 300 [
    "${toString ./zsh/zim/plugins} --source navi.zsh"
  ];
}
