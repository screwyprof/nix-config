{ config, lib, pkgs, ... }:
let
  #theme = "base24-flat";
  #theme = "base24-one-dark";
  theme = "base24-dracula";

  tinted-schemes = pkgs.fetchFromGitHub {
    owner = "tinted-theming";
    repo = "schemes";
    rev = "spec-0.11";
    sha256 = "sha256-Tp1BpaF5qRav7O2TsSGjCfgRzhiasu4IuwROR66gz1o=";
  };

  tinted-shell = pkgs.fetchFromGitHub {
    owner = "tinted-theming";
    repo = "tinted-shell";
    rev = "60c80f53cd3d97c25eb0580e40f0b9de84dac55f";
    sha256 = "sha256-eyZKShUpeIAoxhVsHAm2eqYvMp5e15NtbVrjMWFqtF8=";
  };

  tinted-fzf-src = pkgs.fetchFromGitHub {
    owner = "tinted-theming";
    repo = "tinted-fzf";
    rev = "7646a7e697767271d3dd059bbd9c267163d030a3";
    sha256 = "sha256-Hoj5ib7cOwuuRmOHJd1SyCeyBoMrNTsrqrWgN955zJM=";
  };

  # Create a patched version of tinted-fzf with theme symlinks in ansi/
  tinted-fzf = pkgs.runCommand "tinted-fzf-patched" { } ''
    cp -r ${tinted-fzf-src} $out
    chmod -R +w $out

    cd $out
    mkdir -p ansi-sh
   
    for theme in sh/base16-*.sh sh/base24-*.sh; do
      name=$(basename "$theme")
      ln -s ../ansi/ansi.sh "ansi-sh/$name"
    done
  '';

  # Create bat themes directory with our custom Gopher theme
  gopher-bat = pkgs.runCommand "gopher-bat" { } ''
    mkdir -p $out/themes
    cp ${./Gopher.tmTheme} $out/themes/${theme}.tmTheme
  '';

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
      "${config.xdg.dataHome}/tinted-theming/tinty/repos/tinted-shell".source = assertPath tinted-shell;
      "${config.xdg.dataHome}/tinted-theming/tinty/repos/fzf".source = assertPath tinted-fzf;

      "${config.xdg.dataHome}/tinted-theming/tinty/repos/bat".source = assertPath gopher-bat;

      "${config.xdg.configHome}/zsh/colors.sh".source = assertPath "${tinted-shell}/scripts/${theme}.sh";
      "${config.xdg.configHome}/fzf/colors.sh".source = assertPath "${tinted-fzf}/ansi/ansi.sh";
      "${config.xdg.configHome}/bat/themes/${theme}.tmTheme".source = assertPath ./Gopher.tmTheme;
    };
  };

  programs.zsh = {
    envExtra = lib.mkAfter ''
      # fzf theme
      [ -f ~/.config/fzf/colors.sh ] && source ~/.config/fzf/colors.sh

      # bat theme
      if [[ -f ~/.config/bat/themes/${theme}.tmTheme ]]; then
        export BAT_THEME="${theme}"
      fi
    '';

    initExtra = lib.mkAfter ''
      # bat theme
      # Only rebuild cache if the theme isn't in the themes list
      if ! bat --list-themes | grep -q "${theme}"; then
        bat cache --build
      fi
    '';
  };


  xdg.configFile = {
    "tinted-theming/tinty/config.toml".text = ''
        shell = "zsh -c '{}'"
      default-scheme = "${theme}"
      schemes-dir = "${config.xdg.dataHome}/tinted-theming/tinty/repos/schemes"

      [[items]]
      name = "tinted-shell"
      path = "${config.xdg.dataHome}/tinted-theming/tinty/repos/tinted-shell"
      themes-dir = "scripts"
      hook = "cp -f %f ~/.config/zsh/colors.sh && source ~/.config/zsh/colors.sh"
      supported-systems = ["base16", "base24"]

      [[items]]
      name = "fzf"
      path = "${config.xdg.dataHome}/tinted-theming/tinty/repos/fzf"
      themes-dir = "ansi-sh"
      supported-systems = ["base16", "base24"]
      hook = "cp -f %f ~/.config/fzf/colors.sh && source ~/.config/fzf/colors.sh"

      [[items]]
      name = "bat"
      path = "${config.xdg.dataHome}/tinted-theming/tinty/repos/bat"
      themes-dir = "themes"
      supported-systems = ["base16", "base24"]
      hook = "cp -f %f ~/.config/bat/themes/${theme}.tmTheme && bat cache --build"
    '';
  };
}

