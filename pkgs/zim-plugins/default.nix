{ lib, pkgs }:

pkgs.stdenv.mkDerivation rec {
  pname = "zim-plugins";
  version = "1.0.0";
  src = ./plugins;

  installPhase = ''
    mkdir -p $out/share/zsh/plugins/zim-plugins
    
    # Install each plugin file
    for plugin in *.zsh; do
      if [[ -f "$src/$plugin" ]]; then
        install -D "$src/$plugin" \
          "$out/share/zsh/plugins/zim-plugins/$plugin"
      fi
    done
  '';

  meta = with lib; {
    description = "Local ZIM plugins for ZSH configuration";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
