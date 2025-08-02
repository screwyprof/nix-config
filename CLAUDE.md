# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal Nix configuration for macOS and Linux systems using:
- **Nix Flakes** - Declarative system configuration
- **nix-darwin** - macOS system management  
- **home-manager** - User environment configuration
- **nix-homebrew** - Homebrew integration on macOS

## Command Reference

### System Management

```bash
# System rebuilds
nix-rebuild-host           # Rebuild 'macbook' configuration
nix-rebuild-mac            # Rebuild 'parallels' VM configuration
nix-rebuild <hostname>     # Generic rebuild (Darwin/NixOS)

# Flake operations
nix-check                  # Run flake checks and pre-commit hooks
nix-fmt                    # Format Nix files with nixpkgs-fmt
nix-update                 # Update all flake inputs
nix-update-nixpkgs         # Update nixpkgs only

# Maintenance
nix-cleanup                # Garbage collection + optimization
nix-store-size             # Check Nix store disk usage
```

### Development Environments

```bash
# Language-specific shells
dev go                     # Go development environment
dev rust                   # Rust development environment
dev go make build          # Run commands in Go environment
dev rust cargo test        # Run commands in Rust environment

# Claude with isolated state
dev claude                 # Claude with MCP servers and state isolation
```

## Architecture

### Flake Configuration

The repository is structured as a Nix flake with Darwin systems defined in `flake.nix`:
- **darwinConfigurations.macbook**: Primary MacBook configuration
- **darwinConfigurations.parallels**: Parallels VM configuration
- **System Admin**: User "happygopher" configured at `flake.nix:46-53`

Key inputs:
- nixpkgs (unstable)
- nix-darwin for macOS system management
- home-manager for user environment
- nix-homebrew for declarative Homebrew management
- Pre-commit hooks, rust-overlay, and claude-code

### Module System

Home-manager modules are organized by platform and functionality:
- **Shared modules** (`home/modules/shared/`): Cross-platform configurations
  - `cli/`: Shell (zsh with Zim), CLI tools, themes
  - `core/`: Fonts, vim, system utilities
  - `development/`: Git, direnv, nix tools, containers
- **Platform modules** (`home/modules/darwin/`, `home/modules/linux/`): OS-specific
- **User modules** (`home/users/`): Per-user configurations

The rebuild commands use a function defined in `home/modules/shared/development/nix.nix:22-28` that detects the OS and runs the appropriate rebuild command.

### Shell Environment

ZSH configuration (`home/modules/shared/cli/zsh/default.nix`):
- Zim framework for plugin management
- Modern CLI replacements (eza for tree, etc.)
- GNU utilities available with color support
- History stored in XDG state directory
- You-should-use plugin for alias suggestions (YSU_MODE=ALL)

## Claude Development Environment

The `dev claude` command provides isolated Claude state to prevent project pollution:

1. **Shell Hook** (`dev/claude/flake.nix:60-110`): Configures isolated environment
2. **State Isolation**: Uses SHA-256 hash of project path for unique state directory
3. **MCP Integration**: Sequential-thinking server built from source
4. **Auto-configuration**: Creates `.mcp.json` on shell entry

Environment variables:
- `CLAUDE_CONFIG_DIR`: Isolated configuration directory
- `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR`: Maintains project directory in shell

State location: `~/.local/state/claude/<project-hash>/`

## Development Workflow

### Pre-commit Hooks

Defined in `flake.nix:164-189`, automatically installed by direnv:
- nixpkgs-fmt: Format Nix files
- statix: Static analysis
- deadnix: Find dead code
- nil: Nix language server checks
- flake-checker: Validate flake structure

### Custom Packages

Located in `pkgs/`:
- `navi`: Command-line cheatsheet tool
- `mysides`: macOS Finder sidebar management (Darwin only)

## Important Notes

- Always run `direnv allow` after cloning to load environment
- Homebrew taps are immutable and managed by Nix
- Weekly auto-GC configured, manual cleanup rarely needed
- Use `nix-check` before commits to ensure code quality