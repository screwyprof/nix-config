{ config, lib, pkgs, devUser, ... }: {
  imports = [
    ./shell.nix
    ./darwin.nix
  ];

  home = {
    username = "parallels";
    stateVersion = "23.05";
  };

  programs.home-manager.enable = true;
} 