# Nix Config Architecture

This document describes the architectural patterns and organization used in this nix-config repository.

## High-Level Structure

This repository uses **Nix Flakes** for reproducible system configuration with:

- **nix-darwin** - System-level macOS configuration
- **home-manager** - User environment management
- **nix-homebrew** - Declarative Homebrew integration for GUI apps
- **nix-colors** - Consistent theming across programs

## System Organization

### Host Configurations

Each machine has its own configuration in `hosts/darwin/`:
- **macbook** - Primary M2 MacBook
- **parallels-vm** - Testing VM

### Three-Tier Module System

The configuration uses a hierarchical module system to avoid duplication:

1. **Shared Modules** (`home/modules/shared/`) - Cross-platform configurations
   - CLI tools, shell environment, themes
   - Core utilities and fonts
   - Development tools (Git, direnv)

2. **Platform Modules** (`home/modules/darwin/`, `home/modules/linux/`) - OS-specific configurations
   - macOS: Homebrew integration, Colima, macOS-specific tools
   - Linux: Platform-specific alternatives

3. **User Modules** (`home/users/`) - Per-user configurations
   - User-specific preferences and settings
   - Terminal profiles and application settings

This approach keeps configurations **DRY** - approximately 80% shared, 20% host-specific.

## Configuration Patterns

### Builder Pattern

The flake uses builder functions to generate system configurations:
- `mkDarwinSystem` - Generates Darwin configurations
- `mkHomeManagerConfig` - Generates home-manager configurations with proper module ordering

### Overlay System

Custom packages are provided through flake overlays:
- Custom packages in `pkgs/`
- Platform-specific packages (Darwin-only tools)
- Automatic integration into user environments

### Theming Architecture

Centralized theme management in `home/modules/shared/cli/themes/`:

- **Schemes** - Color definitions (e.g., base24-dracula)
- **Presets** - Theme configurations that map schemes to programs
- **Program Integration** - Per-program theme implementations

This allows changing color schemes in one place and having it propagate across ZSH, bat, iTerm2, etc.

### Development Environments

Isolated development shells in `dev/`:
- Each environment is a separate flake
- Follows consistent pattern for devShells
- Includes language-specific toolchains

## Key Architectural Decisions

### XDG Compliance

All configurations use XDG base directories for consistent file organization.

### Immutable Homebrew Taps

Homebrew taps are managed as flake inputs, making them immutable and reproducible.

### State Management

Clear separation between:
- **Immutable state** - Managed by Nix (configurations, packages)
- **Mutable state** - User data, application state

### Security

- TouchID for sudo authentication (Darwin)
- Trusted users configuration for Nix operations
- SSH configuration management
- No secrets in configuration files

## CLI Tools Philosophy

Modern replacements for traditional Unix tools:
- **eza** instead of `ls` - Icons, git integration, tree view
- **bat** instead of `cat` - Syntax highlighting, git integration
- **fd** instead of `find` - Faster, more intuitive
- **ripgrep** instead of `grep` - Faster, better defaults
- **fzf** - Fuzzy finder integrated everywhere
- **zoxide** instead of `cd` - Smart directory navigation

These are integrated with:
- **ZIM Framework** - Fast ZSH plugin management
- **Powerlevel10k** - Instant prompt, customizable theme
- **alias-teacher** - Helps discover and learn aliases

## Automation

### Pre-commit Hooks

Automatically enforced via direnv:
- **nixpkgs-fmt** - Code formatting
- **statix** - Linting and static analysis
- **deadnix** - Find dead code
- **nil** - Language server checks
- **flake-checker** - Validate flake structure

### Garbage Collection

Weekly automatic garbage collection configured via launchd with size limits to prevent unbounded disk usage.

### Development Workflow

- **direnv** - Automatic environment activation per directory
- **Project isolation** - Each project can have its own `flake.nix`
- **Reproducible builds** - Flake.lock pins all dependencies

## Custom Packages

### alias-teacher

Enhanced ZSH plugin that helps discover aliases:
- Finds most specific alias matches
- Shows related aliases for discovery
- Fork of zsh-you-should-use with improvements

## Performance Optimizations

- Build parallelization enabled
- Binary cache configured
- Automatic store optimization
- Minimal rebuilds through proper dependency management

## Maintenance Approach

- **Shared first** - Common configurations in shared modules
- **Platform overrides** - Platform-specific modules extend shared base
- **User customization** - User modules for personal preferences
- **Host specificity** - Minimal host-specific configurations

This design allows the configuration to be:
- **Portable** - Easy to add new hosts or platforms
- **Maintainable** - Changes in shared modules benefit all hosts
- **Flexible** - Easy to override at any level
