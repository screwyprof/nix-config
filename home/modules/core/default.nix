{ config, lib, pkgs, ... }: {
  imports = [
    ./git.nix
    ./development.nix
    ./packages.nix
  ];
} 