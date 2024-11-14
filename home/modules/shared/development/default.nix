{ config, lib, pkgs, ... }:

let
  # Centralize package groups
  devTools = with pkgs; [
    nix-prefetch-github
    nix-prefetch-git
    nixpkgs-fmt
    statix
    deadnix
    shellcheck
  ];

  # Centralize environment variables
  defaultEnv = {
    K9S_EDITOR = "vim";
    CARGO_NET_GIT_FETCH_WITH_CLI = "true";
  };
in
{
  imports = [
    ./git.nix
    ./containers
    ./golang.nix
    ./node.nix
    ./vscode.nix
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home = {
    packages = devTools;
    sessionVariables = defaultEnv;
  };
}
