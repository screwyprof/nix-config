{ config, lib, pkgs, ... }:

let
  nixDevTools = with pkgs; [
    # Nix formatting and linting
    nixpkgs-fmt # Nix code formatter
    statix # Lints and suggestions for Nix code
    deadnix # Find dead code in .nix files

    # Nix development tools
    nix-prefetch-github # Prefetch sources from GitHub
    nix-prefetch-git # Prefetch git repositories

    # Additional Nix tools
    nixpkgs-hammering # Additional Nix code checks
    #nil               # Nix language server (for IDE support)
    #alejandra         # Alternative Nix formatter
  ];

  # Nix-specific aliases
  nixAliases = {
    # Basic operations
    nix-check = "nix flake check";
    nix-cleanup = "nix-collect-garbage -d && nix store optimise";

    # Development helpers
    nix-update = "nix flake update";
    nix-update-nixpkgs = "nix flake lock --update-input nixpkgs";

    # Format and check
    nix-fmt = "nixpkgs-fmt ."; # Format all files
    nix-fmt-check = "nixpkgs-fmt --check ."; # Check without modifying
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
