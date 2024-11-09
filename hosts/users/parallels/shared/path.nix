{ config, lib, pkgs, ... }: {
  home.sessionPath = [
    "$HOME/.local/bin"  # Local user binaries
  ];
} 