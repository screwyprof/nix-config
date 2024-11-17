{ config, pkgs, ... }:
let
  tinted-schemes = pkgs.fetchFromGitHub {
    owner = "tinted-theming";
    repo = "schemes";
    rev = "spec-0.11";
    sha256 = "sha256-Tp1BpaF5qRav7O2TsSGjCfgRzhiasu4IuwROR66gz1o=";
  };

  tinted-shell = pkgs.fetchFromGitHub {
    owner = "tinted-theming";
    repo = "tinted-shell";
    rev = "main";
    sha256 = "sha256-eyZKShUpeIAoxhVsHAm2eqYvMp5e15NtbVrjMWFqtF8=";
  };

  tinted-fzf = pkgs.fetchFromGitHub {
    owner = "tinted-theming";
    repo = "tinted-fzf";
    rev = "main";
    sha256 = "sha256-mIOkmHJTg3xZ9bYNbtUUjeF1m8THaDBalYkDONQgRKY=";
  };

  # Assert that a path exists or throw an error
  assertPath = path:
    assert builtins.pathExists path;
    path;
in
{
  home = {
    packages = [ pkgs.tinty ];
    file = {
      "${config.xdg.dataHome}/tinted-theming/tinty/repos/schemes".source = assertPath tinted-schemes;
      "${config.xdg.dataHome}/tinted-theming/tinty/repos/shell".source = assertPath tinted-shell;
      "${config.xdg.dataHome}/tinted-theming/tinty/repos/fzf".source = assertPath tinted-fzf;
      "${config.xdg.configHome}/zsh/colors.sh".source = assertPath "${tinted-shell}/scripts/base16-catppuccin-frappe.sh";
      "${config.xdg.configHome}/fzf/colors.sh".source = assertPath "${tinted-fzf}/ansi/ansi.sh";
    };
  };

  xdg.configFile = {
    "tinted-theming/tinty/config.toml".text = ''
      shell = "zsh -c '{}'"
      default-scheme = "base16-tokyo-night-storm"
      schemes-dir = "${config.xdg.dataHome}/tinted-theming/tinty/repos/schemes"

      # Item configurations
      [[items]]
      name = "tinted-shell"
      path = "${config.xdg.dataHome}/tinted-theming/tinty/repos/shell"
      themes-dir = "scripts"
      #hook = "source %f"
      hook = "cp -f %f ~/.config/zsh/colors.sh && source ~/.config/zsh/colors.sh"
      supported-systems = ["base16", "base24"]

      [[items]]
      name = "fzf"
      path = "${config.xdg.dataHome}/tinted-theming/tinty/repos/fzf"
      themes-dir = "ansi"
      hook = "cp -f %f ~/.config/fzf/colors.sh && source ~/.config/fzf/colors.sh"
    '';
  };
}
