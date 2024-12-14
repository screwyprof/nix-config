# Nix Configuration

Personal Nix configuration for MacOS (Apple Silicon).

## Prerequisites

1. Sign in to your iCloud account:
   - Open System Settings
   - Click "Sign in with your Apple ID"
   - Sign in with your Apple ID and password
   - This enables App Store access and iCloud features

2. Make sure Git is available:
   ```bash
   # For MacOS, install Xcode Command Line Tools:
   xcode-select --install
   ```

### Optional: iCloud Drive Setup

If you want to use `~/Projects` folder synced with iCloud:

1. Open the Apple menu and select System Settings
2. Click your name at the top of the sidebar
3. Click iCloud on the right
4. Click iCloud Drive
5. Make sure iCloud Drive is turned on
6. Turn on Desktop & Documents Folders
7. Click Done

Note: After first build, `~/Projects` symlink will be created and will start working once `iCloud` sync completes.

## Installation

1. Install Nix by following the official installation guide:
   [Nix Installation Guide](https://nixos.org/download)

2. Enable flakes and configure Nix:
   ```bash
   mkdir -p ~/.config/nix
   echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
   echo "download-buffer-size = 100000000" >> ~/.config/nix/nix.conf
   ```

3. Clone and build the configuration:
   ```bash
   # For first-time build (when darwin-rebuild is not yet available):
   nix run nix-darwin -- switch --flake '.#macbook'
   
   # For subsequent builds, either use:
   darwin-rebuild switch --flake '.#macbook'
   # or the provided alias:
   nix-rebuild-host
   ```

4. Set up pre-commit hooks:
   ```bash
   nix develop
   # once shell is open, run:
   exit
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

## Development Shells

This configuration provides development shells for various programming languages. These shells provide isolated development environments with all necessary tools and dependencies.

### Available Shells

- **Go Development Shell**:
  ```bash
  # Run a command in the Go environment
  nix develop '/Users/happygopher/nix-config#go' --command go test -v ./...
  
  # Or enter the shell
  nix develop '/Users/happygopher/nix-config#go'
  ```
  Provides: Go 1.23, gopls, delve, golangci-lint, and other Go tools.

- **Rust Development Shell**:
  ```bash
  # Run a command in the Rust environment
  nix develop '/Users/happygopher/nix-config#rust' --command cargo test
  
  # Or enter the shell
  nix develop '/Users/happygopher/nix-config#rust'
  ```
  Provides: Rust toolchain (defined in rust-toolchain.toml), cargo extensions, and coverage tools.

### Usage Notes

- Use single quotes around the flake path to prevent shell globbing: `'/path/to/nix-config#shell'`
- You have to use a full path to the flake or the shell will not be found
- The shells are project-agnostic and can be used with any project of the respective language
- Each shell provides its own isolated environment with specific tools and configurations
- Development shells are defined in `dev/<language>/shell.nix`

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

## Post-Installation Steps

### Safari Extensions
1. After Noir is installed via masApps, enable it in Safari:
   - Open Safari
   - Go to Safari > Settings > Extensions
   - Enable Noir
   - Configure Noir settings to your preference
2. Enable and configure AdGuard:
   - Open Safari > Settings > Extensions
   - Enable AdGuard
   - Click on AdGuard icon in Safari toolbar to:
     - Enable filters you want to use
     - Configure custom rules (if needed)
     - Enable/disable protection for specific websites