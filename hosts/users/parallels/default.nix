{ config, lib, pkgs, devUser, isDarwin, ... }: {
  imports = [
    ./shared          # Shared user configurations 
  ] ++ lib.optionals isDarwin [
    ./darwin          # Darwin-specific configs
  ];

  home = {
    username = "parallels";
    stateVersion = "23.05";
  };

  programs.home-manager.enable = true;
} 