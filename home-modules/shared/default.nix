{ config, lib, pkgs, ... }: {
  imports = [
    ./fonts
    ./zsh
    ./containers
    ./development
  ];
}
