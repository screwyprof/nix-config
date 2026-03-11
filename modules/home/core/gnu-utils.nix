{
  flake.modules.homeManager.core-gnu-utils =
    { lib, pkgs, ... }:
    let
      gnuUtils = with pkgs; [
        coreutils
        findutils
        gnugrep
        gnused
        gnutar
        gawk
        gnumake
      ];
    in
    {
      home = {
        packages = gnuUtils;

        # Prepend GNU utils to PATH so they shadow macOS BSD equivalents
        sessionVariables.PATH = lib.concatStringsSep ":" (map (pkg: "${pkg}/bin") gnuUtils ++ [ "$PATH" ]);
      };
    };
}
