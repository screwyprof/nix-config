{ config, lib, pkgs, ... }: {
  imports = [
    ./fonts.nix
    ./gnu-utils.nix
    ./neofetch
    ./fastfetch
    ./vim.nix
  ];
}
