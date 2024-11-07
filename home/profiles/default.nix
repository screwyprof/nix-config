{ pkgs, ... }: {
  home.stateVersion = "23.05";
  programs.home-manager.enable = true;

  imports = [
    ../common/development.nix
    ../common/shell.nix
    ../common/git.nix
    ../common/packages.nix
  ];
} 