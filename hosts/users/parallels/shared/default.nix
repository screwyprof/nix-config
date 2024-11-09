{ config, lib, pkgs, ... }: {
  imports = [
    ./path.nix 
    ./git.nix
    ./gnu-utils.nix
    ./fonts.nix 
    ./shell
    ./development.nix
    ./node.nix
    ./vscode.nix
  ];
} 