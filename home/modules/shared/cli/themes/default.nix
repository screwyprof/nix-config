{ config, pkgs, lib, ... }:
let
  tinted-schemes = pkgs.fetchFromGitHub {
    owner = "tinted-theming";
    repo = "schemes";
    rev = "spec-0.11";
    sha256 = "sha256-Tp1BpaF5qRav7O2TsSGjCfgRzhiasu4IuwROR66gz1o=";
  };

  tinted-fzf = pkgs.fetchFromGitHub {
    owner = "tinted-theming";
    repo = "tinted-fzf";
    rev = "main";
    sha256 = "sha256-mIOkmHJTg3xZ9bYNbtUUjeF1m8THaDBalYkDONQgRKY=";
  };
in
{
  home = {
    #packages = [ pkgs.tinty ];
    file = {
      "${config.xdg.dataHome}/tinted-theming/tinty/repos/schemes".source = lib.mkForce tinted-schemes;
      "${config.xdg.dataHome}/tinted-theming/tinty/repos/fzf".source = lib.mkForce tinted-fzf;
      "${config.xdg.configHome}/fzf/colors.sh".source = "${tinted-fzf}/sh/base16-catppuccin-frappe.sh";
    };
  };

  #   xdg.configFile = {
  #     "tinted-theming/tinty/config.toml".text = ''
  #       shell = "zsh -c '{}'"
  #       default-scheme = "base16-tokyo-night-storm"
  #       schemes-dir = "${config.xdg.dataHome}/tinted-theming/tinty/repos/schemes"

  #       [[items]]
  #       name = "fzf"
  #       path = "${config.xdg.dataHome}/tinted-theming/tinty/repos/fzf"
  #       themes-dir = "sh"
  #       hook = "cp -f %f ~/.config/fzf/colors.sh && source ~/.config/fzf/colors.sh"
  #     '';
  #   };
}
