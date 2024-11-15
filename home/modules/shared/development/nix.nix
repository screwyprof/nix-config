{ pkgs, ... }:

let
  nixDevTools = with pkgs; [
    # Nix formatting and linting
    nixpkgs-fmt # Nix code formatter
    statix # Lints and suggestions for Nix code
    deadnix # Find dead code in .nix files
    nixpkgs-lint # Semantic linter using tree-sitter

    # Nix development tools
    nix-prefetch-github
    nix-prefetch-git
    nixpkgs-hammering
  ];

  nixAliases = {
    # Basic operations
    nix-check = "nix flake check";
    nix-cleanup = ''
      nix-collect-garbage -d && \
      nix store optimise 2>&1 | grep -v "warning: skipping suspicious writable file"
    '';
    nix-update = "nix flake update";
    nix-update-nixpkgs = "nix flake lock --update-input nixpkgs";

    # Individual tools for development
    nix-fmt = "nixpkgs-fmt .";
    nix-lint = "nixpkgs-lint";
  } // (if pkgs.stdenv.isDarwin then {
    nix-rebuild-host = "nix-fmt && nix flake check && darwin-rebuild switch --flake '.#macbook'";
    nix-rebuild-mac = "nix-fmt && nix flake check && darwin-rebuild switch --flake '.#parallels'";
  } else { });
in
{
  home.packages = nixDevTools;

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    zsh.shellAliases = nixAliases;
  };
}
