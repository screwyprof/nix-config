{ config, lib, pkgs, ... }: {
  imports = [
    ./path.nix
    ./git.nix
    ./vim.nix
    ./bat.nix
    ./gnu-utils.nix
    ./fonts.nix
    ./shell
    ./development.nix
    ./golang.nix
    ./node.nix
    ./vscode.nix
  ];
}
