{
  flake.modules.homeManager.core-gnu-utils =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        coreutils
        findutils
        gnugrep
        gnused
        gnutar
        gawk
        gnutls
        gnumake
      ];
    };
}
