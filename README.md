# Nix Configuration

Personal Nix configuration for macOS and Linux systems.

## Setup

### Prerequisites

1. Sign in to your iCloud account and enable iCloud Drive:
   - Open System Settings > Apple ID
   - Sign in if needed
   - Enable iCloud Drive
   - Turn on Desktop & Documents Folders

   Note: After first build, `~/Projects` symlink will be created and will start working once `iCloud` sync completes.

2. Make sure Git is available:
   ```bash
   # For MacOS, install Xcode Command Line Tools:
   xcode-select --install
   ```

3. *Optionally* Install Rosetta 2:
   ```bash
   softwareupdate --install-rosetta --agree-to-license
   ```

4. Install Nix package manager:
   ```bash
   sh <(curl -L https://nixos.org/nix/install)
   ```

5. Clone this repository:
   ```bash
   git clone https://github.com/your-username/nix-config.git ~/.config/nix-config
   cd ~/.config/nix-config
   ```

### Initial Build

```bash
# For first-time build:
sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin

sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake '.#macbook'

# For subsequent builds:
nix-rebuild-host    # For local MacBook
nix-rebuild-mac     # For Parallels VM
```

### Post-Installation Setup

#### Safari Extensions

1. Enable Noir:
   - Open Safari > Settings > Extensions
   - Enable Noir
   - Configure preferences

2. Configure AdGuard:
   - Open Safari > Settings > Extensions
   - Enable AdGuard
   - Configure filters and rules

## System Management

### Common Commands

```bash
# System rebuilds
nix-rebuild-host           # Rebuild macbook configuration
nix-rebuild-mac            # Rebuild parallels configuration

# Updates (daily use)
nix-update                 # Update all flake inputs
nix-update-nixpkgs         # Update only packages

# Emergency maintenance (rarely needed)
nix-cleanup                # Manual cleanup + optimization (auto-GC handles this)
nix-store-size             # Check store disk usage
```

## Development

This configuration uses [direnv](https://direnv.net/) to automatically:
- Load development environment
- Install pre-commit hooks
- Set up language-specific tools

Just run:
```bash
direnv allow
```

### Nix Development Tools

All Nix development tools are managed through home-manager (`home/modules/shared/development/nix.nix`):
- Formatting and linting (nixpkgs-fmt, statix, deadnix, nil)
- Development utilities (nix-prefetch-github, nix-prefetch-git)
- Flake checking and hammering

Essential commands:
```bash
nix-fmt            # Format Nix files
nix-check          # Check flake (includes linting via pre-commit hooks)
nix-update         # Update all flake inputs
nix-update-nixpkgs # Update only packages
```

### Pre-commit Hooks

The repository uses pre-commit hooks for Nix files:
- Format checking (nixpkgs-fmt)
- Static analysis (statix)
- Dead code detection (deadnix)
- Language server checks (nil)
- Flake checking

The hooks are automatically installed by direnv. To enable them manually:
```bash
nix develop
```

### Language-Specific Development Shells

Quick access to development environments:
```bash
dev go               # Enter Go development shell
dev rust             # Enter Rust development shell

# Or run commands directly
dev go make build    # Run make build in Go environment
dev rust cargo test  # Run cargo test in Rust environment
```

#### Go Development Shell
Provides: golang, gopls, delve, golangci-lint
```bash
dev go              # Enter shell
dev go make build   # Run command
```

#### Rust Development Shell
Provides: Rust toolchain, cargo extensions, coverage tools
```bash
dev rust            # Enter shell
dev rust cargo test # Run command
```

### Stacking Development Environments

You can combine multiple development environments using direnv. Create a `.envrc` file in your project:

```bash
# Example .envrc for a Go + Claude project
use flake "/Users/happygopher/nix-config/dev/go"
use flake "/Users/happygopher/nix-config/dev/claude"
```

Or for a Rust + Claude project:
```bash
# Example .envrc for a Rust + Claude project
use flake "/Users/happygopher/nix-config/dev/rust"
use flake "/Users/happygopher/nix-config/dev/claude"
```

Or combine all three:
```bash
# Example .envrc for Go + Rust + Claude project
use flake "/Users/happygopher/nix-config/dev/go"
use flake "/Users/happygopher/nix-config/dev/rust"
use flake "/Users/happygopher/nix-config/dev/claude"
```

Then activate the environment:
```bash
direnv allow
```

**What happens when stacking:**
- Each environment's tools are added to PATH
- Environment variables are properly isolated using project-specific hashes
- Same project hash is used across all environments for consistency
- All tools from all environments become available in your shell

**Note:** Shell aliases from development environments are not available when using direnv (only when using `dev shell` directly). Use full commands like `cargo build`, `go test`, etc.

## Resources
- [Official Nix Website](https://nixos.org)
- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Nix Darwin](https://github.com/LnL7/nix-darwin)
- [Home Manager](https://github.com/nix-community/home-manager)
- [Nix-Homebrew](https://github.com/zhaofengli/nix-homebrew)
