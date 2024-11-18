{ pkgs, ... }:

let
  # Centralize package groups
  devTools = with pkgs; [
    shellcheck
  ];

  # Centralize environment variables
  defaultEnv = {
    K9S_EDITOR = "vim";
  };
in
{
  imports = [
    ./git.nix
    ./nix.nix
    ./containers
    ./golang.nix
    ./node.nix
    ./rust.nix
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
