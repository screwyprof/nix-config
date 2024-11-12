{ config, lib, pkgs, ... }: {
  imports = [
    ./core
    ./cli
    ./development
  ];
}
