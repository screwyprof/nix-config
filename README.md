# Nix Configuration

Personal Nix configuration for MacOS (Apple Silicon).

## Installation

1. Install Nix by following the official installation guide:
   [Nix Installation Guide](https://nixos.org/download)

2. Enable flakes by creating the nix configuration directory and file:
   ```bash
   mkdir -p ~/.config/nix
   echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
   ```

3. Build and switch to the configuration:
   ```bash
   darwin-rebuild switch --flake '.#macbook'
   ```

4. Set up pre-commit hooks:
   ```bash
   nix develop
   pre-commit install
   ```
   This will install the following hooks:
   - nixpkgs-fmt (Nix code formatter)
   - statix (Nix linter)
   - deadnix (Dead code finder)
   - nil (Nix LSP linter)

## Features
- Nix-Darwin system configuration
- Home Manager for user environment
- Nix-Homebrew integration with managed taps
- Pre-commit hooks for Nix code quality

## Useful Commands

```bash
# Basic Operations
nix-check              # Check flake for errors
nix-update             # Update all flake inputs
nix-update-nixpkgs     # Update only nixpkgs input
nix-cleanup            # Delete old generations and collect garbage
nix-optimise           # Optimize the Nix store (deduplication and hard-linking)

# Development Tools
nix-fmt               # Format nix files
nix-lint              # Lint nix files

# System Rebuild (MacOS)
nix-rebuild-host      # Format, check, and rebuild system
```

## Resources
- [Official Nix Website](https://nixos.org)
- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Nix Darwin](https://github.com/LnL7/nix-darwin)
- [Home Manager](https://github.com/nix-community/home-manager)
- [Nix-Homebrew](https://github.com/zhaofengli/nix-homebrew)