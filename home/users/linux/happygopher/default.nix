{ config, ... }: {
  imports = [
    ../../../home/modules/shared
    ../../../home/modules/linux/colima.nix
  ];

  home = { };

  xdg.dataHome = "${config.home.homeDirectory}/.local/share";
}
