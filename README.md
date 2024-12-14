# Nix Configuration

Personal Nix configuration for MacOS (Apple Silicon).

## Features
- Nix-Darwin system configuration
- Home Manager for user environment
- Nix-Homebrew integration with managed taps
- Development shells for Go, Rust, and Nix
- Pre-commit hooks for Nix code quality

## Prerequisites

1. Sign in to your iCloud account

2. Make sure Git is available:
   ```bash
   # For MacOS, install Xcode Command Line Tools:
   xcode-select --install
   ```

3. Install Nix package manager:
   ```bash
   sh <(curl -L https://nixos.org/nix/install)
   ```

4. *Optionally* Install Rosetta 2:
   ```bash
   # Install Rosetta 2 (required for some packages)
   softwareupdate --install-rosetta --agree-to-license
   ```

5. Clone this repository:
   ```bash
   git clone https://github.com/your-username/nix-config.git ~/.config/nix-config
   cd ~/.config/nix-config
   ```

## Build the System

```bash
# For first-time build (when darwin-rebuild is not yet available):
nix run nix-darwin -- switch --flake '.#macbook'

# For subsequent builds, either use any of the following:
- darwin-rebuild switch --flake '.#macbook'
- nix-rebuild macbook
- nix-rebuild-host
   ```

## Post-Installation

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

## System Management

The configuration provides a flexible `nix-rebuild` command that can rebuild any configuration:

```bash
nix-rebuild <config-name>   # Rebuild any configuration by name
```

For convenience, there are also aliases for common configurations:
```bash
nix-rebuild-host   # Rebuild macbook configuration
nix-rebuild-mac    # Rebuild parallels configuration
```

## Development Environment

This project uses [direnv](https://direnv.net/) to automatically load the development environment when you enter the project directory.

1. Allow direnv:
   ```bash
   direnv allow
   ```

This will automatically:
- Load the Nix development environment
- Set up pre-commit hooks for:
  - nixpkgs-fmt (Nix code formatter)
  - statix (Nix linter)
  - deadnix (dead code elimination)

The hooks will run automatically when you commit changes to Nix files.

## Development Shells

Quick access to development environments:
```bash
dev go               # Enter Go development shell
dev rust             # Enter Rust development shell
dev nix              # Enter Nix development shell

# Or run commands directly
dev go make build    # Run make build in Go environment
dev rust cargo test  # Run cargo test in Rust environment
```

*Usage Notes*:
- Use `dev <shell>` for quick access to any development shell
- Each shell provides its own isolated environment with specific tools
- Development shells are defined in `dev/<language>/shell.nix`

### Go Development Shell

```bash
dev go              # Enter shell
dev go make build   # Run command
```

Provides: golang (from go.mod or latest), gopls, delve, golangci-lint, and other Go tools.

### Rust Development Shell

```bash
dev rust            # Enter shell
dev rust cargo test # Run command
```

Provides: Rust toolchain (from rust-toolchain.toml), cargo extensions, and coverage tools.

### Nix Development Shell

```bash
dev nix            # Enter basic shell
```

Provides:
- Formatting and linting: nixpkgs-fmt, statix, deadnix, nil
- Development tools: nix-prefetch-github, nix-prefetch-git

Available commands:
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
```

For additional features like [pre-commit hooks](https://github.com/cachix/pre-commit-hooks.nix):
```bash
nix develop ./dev/nix  # Enter flake shell with hooks
```

This adds:
- Pre-commit hooks for auto-formatting and linting
- Project-standard hook configurations

## Resources
- [Official Nix Website](https://nixos.org)
- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Nix Darwin](https://github.com/LnL7/nix-darwin)
- [Home Manager](https://github.com/nix-community/home-manager)
- [Nix-Homebrew](https://github.com/zhaofengli/nix-homebrew)