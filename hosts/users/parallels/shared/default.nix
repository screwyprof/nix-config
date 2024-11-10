{ config, lib, pkgs, ... }: {
  imports = [
    ./path.nix
    ./fonts.nix
    ./bat.nix
    ./moar.nix
    ./gnu-utils.nix
    ./git.nix
    ./vim.nix
    ./shell
    ./development.nix
    ./golang.nix
    ./node.nix
    ./vscode.nix
  ];
}
