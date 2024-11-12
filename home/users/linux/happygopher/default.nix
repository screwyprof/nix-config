{ config, lib, pkgs, ... }: {
  imports = [
    ../../../home/modules/shared
    ../../../home/modules/linux/colima.nix
  ];

  home = {
    username = "happygopher";
    homeDirectory = "/home/happygopher";
  };

  xdg.dataHome = "${config.home.homeDirectory}/.local/share";
}
