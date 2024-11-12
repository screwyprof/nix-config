{ config, lib, pkgs, ... }: {
  imports = [
    ./bat.nix
    ./moar.nix
    ./gnu-utils.nix
    ./vim.nix
    ./cheat.nix
    ./neofetch.nix
    ./tldr.nix
    ./docker.nix
    ./colima.nix
    ./development.nix
    ./golang.nix
    ./node.nix
    ./vscode.nix
  ];
}
