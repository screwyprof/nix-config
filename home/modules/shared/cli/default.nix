{ config, lib, pkgs, ... }: {
  imports = [
    ./zsh
    ./bat.nix
    ./moar.nix
    ./cheat.nix
    ./tldr.nix
  ];
}
