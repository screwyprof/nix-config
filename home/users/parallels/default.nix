{ config, lib, pkgs, devUser, ... }: {
  imports = [
    ../../common/development.nix
    ../../common/git.nix
    ../../common/shell.nix
    ../../common/packages.nix
  ];

  home = {
    username = "parallels";
    stateVersion = "23.05";
  };

  programs.home-manager.enable = true;
} 