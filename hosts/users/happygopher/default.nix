{ config, lib, pkgs, devUser, isDarwin, ... }: {
  imports = [
    ../../../modules
  ] ++ lib.optionals isDarwin [
    ./darwin
  ];

  home = {
    username = "parallels";
    stateVersion = "23.05";
  };

  programs.home-manager.enable = true;
}
