{ lib, stdenv }:

stdenv.mkDerivation rec {
  pname = "alias-teacher";
  version = "2.0.0";

  src = ./.;

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/share/zsh/plugins/alias-teacher
    mkdir -p $out/share/doc/alias-teacher
    cp alias-teacher.plugin.zsh $out/share/zsh/plugins/alias-teacher/
    cp LICENSE $out/share/doc/alias-teacher/
    cp README.md $out/share/doc/alias-teacher/
  '';

  meta = with lib; {
    description = "Enhanced ZSH plugin that helps you learn and use shell aliases effectively";
    longDescription = ''
      alias-teacher is an enhanced fork of zsh-you-should-use that improves alias
      discovery and learning. It finds the most specific alias matches and shows
      related aliases to help users discover commands they didn't know existed.
    '';
    homepage = "https://github.com/happygopher/alias-teacher";
    license = licenses.gpl3Only;
    maintainers = [ ];
    platforms = platforms.unix;
  };
}
