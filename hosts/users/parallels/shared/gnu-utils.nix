{ config, lib, pkgs, ... }: {
  home.sessionPath = [
    "${pkgs.coreutils}/bin"
    "${pkgs.findutils}/bin"
    "${pkgs.gnugrep}/bin"
    "${pkgs.gnused}/bin"
    "${pkgs.gnutar}/bin"
    "${pkgs.gawk}/bin"
  ];

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
} 