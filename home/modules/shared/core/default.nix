{ config, lib, pkgs, ... }: {
  imports = [
    ./fonts.nix
    ./gnu-utils.nix
    ./neofetch
    ./vim.nix
  ];
}
