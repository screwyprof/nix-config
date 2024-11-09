{ config, lib, pkgs, ... }: {
  imports = [
    ./git.nix
    ./shell
    ./packages.nix
    ./development.nix
  ];
} 