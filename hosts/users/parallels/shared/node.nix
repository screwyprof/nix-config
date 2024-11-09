{ config, lib, pkgs, ... }: {
  home.sessionPath = [
    "$PNPM_HOME"
  ];

  home.sessionVariables = {
    PNPM_HOME = "$HOME/Library/pnpm";
  };
} 