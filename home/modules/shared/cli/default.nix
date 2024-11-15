{ config, lib, pkgs, ... }: {
  imports = [
    ./zsh
    ./fzf.nix
    ./bat.nix
    ./moar.nix
    ./cheat.nix
    ./tldr.nix
  ];
}
