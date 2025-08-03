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

The repository is structured as a Nix flake with Darwin systems defined in [`flake.nix`](flake.nix):

**System Configurations:**
- **darwinConfigurations.macbook**: Primary MacBook configuration ([`hosts/darwin/macbook/`](hosts/darwin/macbook/))
- **darwinConfigurations.parallels**: Parallels VM configuration ([`hosts/darwin/parallels-vm/`](hosts/darwin/parallels-vm/))

**Core System Admin:** User "happygopher" configured at [`flake.nix:50-54`](flake.nix:50)

**Key Flake Inputs:**
- `nixpkgs` (unstable channel)
- `nix-darwin` for macOS system management
- `home-manager` for user environment
- `nix-homebrew` + Homebrew taps for declarative Homebrew
- `nix-colors` for consistent theming
- `rust-overlay` for Rust toolchain management
- `claude-code` for Claude development integration
- Pre-commit hooks and development tools

**Architecture Patterns:**
- **Builder Functions**: [`mkDarwinSystem`](flake.nix:92) generates Darwin configurations
- **Overlay System**: Custom packages and platform-specific overlays ([`flake.nix:61-72`](flake.nix:61))
- **Multi-system Support**: `supportedSystems` covers aarch64-darwin, x86_64-darwin, x86_64-linux

### Host Configuration Architecture

**Shared Darwin Configuration** ([`hosts/darwin/shared/`](hosts/darwin/shared/)):
- **Nix Configuration**: Performance optimizations, cache configuration, experimental features
- **Security**: TouchID for sudo authentication
- **Homebrew**: Global configuration with automatic updates and cleanup
- **Garbage Collection**: Weekly automatic GC with size limits
- **Common Applications**: Shared casks (browsers, development tools, utilities)

**Host-specific Configurations:**
- **macbook**: Minimal host-specific overrides
- **parallels-vm**: VM-specific configurations with multiple users

### Module System Architecture

**Three-tier Module Organization:**

1. **Shared Modules** ([`home/modules/shared/`](home/modules/shared/)) - Cross-platform:
   - **CLI**: Shell environment, command-line tools, themes
   - **Core**: Fonts, vim, system utilities, GNU tools
   - **Development**: Git, direnv, development environments

2. **Platform Modules** ([`home/modules/darwin/`](home/modules/darwin/), [`home/modules/linux/`](home/modules/linux/)) - OS-specific:
   - **Darwin**: Homebrew integration, Colima, coredumps, macOS-specific tools
   - **Linux**: Platform-specific alternatives and configurations

3. **User Modules** ([`home/users/`](home/users/)) - Per-user configurations:
   - User-specific preferences, terminal profiles, application settings
   - Organized by platform: `darwin/happygopher/`, `darwin/parallels/`, `linux/happygopher/`

**Home-manager Integration Pattern** ([`flake.nix:82-89`](flake.nix:82)):
```nix
mkHomeManagerConfig = { username, ... }: {
  imports = [
    ./home/modules/shared    # System independent
    ./home/modules/darwin    # System specific
    (./home/users/darwin + "/${username}")  # User specific
    inputs.nix-index-database.homeModules.nix-index
  ];
};
```

### Theming System Architecture

**Centralized Theme Management** ([`home/modules/shared/cli/themes/`](home/modules/shared/cli/themes/)):

**Theme Structure:**
- **Schemes**: Color definitions ([`schemes/base24-dracula.nix`](home/modules/shared/cli/themes/schemes/base24-dracula.nix))
- **Presets**: Theme configurations with program mappings ([`presets/default.nix`](home/modules/shared/cli/themes/presets/default.nix))
- **Program Integration**: Per-program theme implementations ([`programs/`](home/modules/shared/cli/themes/programs/))

**Dynamic Theme Loading** ([`themes/default.nix:8-21`](home/modules/shared/cli/themes/default.nix:8)):
```nix
importProgram = program:
  let
    baseModule = ./programs/${program}/default.nix;
    themeModule = activePreset.programs.${program} or null;
  in
  baseImport ++ themeImport;
```

**Supported Programs:**
- **ZSH**: Syntax highlighting, ANSI colors, Powerlevel10k themes
- **Bat**: Syntax highlighting themes
- **iTerm2**: Color profiles and terminal themes

**Color Utilities** ([`themes/default.nix:36-48`](home/modules/shared/cli/themes/default.nix:36)):
- `hexToRGB`: Convert hex colors to RGB components
- `formatRGB`: Format RGB for ANSI sequences
- Integration with nix-colors for standardized color schemes

### CLI Tools Integration

**Modern CLI Replacements:**
- **eza**: Enhanced `ls` with icons, git integration, tree view
- **bat**: Enhanced `cat` with syntax highlighting and git integration
- **fzf**: Fuzzy finder with extensive preview integration
- **zoxide**: Smart directory navigation
- **ripgrep**: Fast grep replacement with smart defaults

**FZF Integration Pattern** ([`cli/fzf.nix`](home/modules/shared/cli/fzf.nix)):
- **File Discovery**: fd-based file and directory widgets
- **Smart Previews**: Context-aware previews with eza/bat
- **SSH Completion**: Enhanced SSH host discovery from multiple sources
- **Environment Variables**: Interactive variable exploration
- **Git Integration**: Forgit plugin for git operations

**ZIM Framework Integration** ([`cli/zsh/zim/`](home/modules/shared/cli/zsh/zim/)):
- **Plugin Management**: Declarative plugin loading with ordering
- **Custom Plugins**: Local plugin integration (navi, zoxide, enhanced-paste)
- **Theme Integration**: Coordinated with theming system
- **Performance**: Optimized loading order and initialization

### Development Environments

**Isolated Development Shells** ([`dev/`](dev/)):

**Architecture Pattern:**
```nix
# Each dev environment follows this structure:
{
  inputs = { nixpkgs, flake-utils, ... };
  outputs = { ... }: flake-utils.lib.eachDefaultSystem (system: {
    devShells.default = import ./shell.nix { inherit pkgs; };
  });
}
```

**Available Environments:**
- **Go** ([`dev/go/`](dev/go/)): Go toolchain with common development tools
- **Rust** ([`dev/rust/`](dev/rust/)): Rust with overlay integration and toolchain management
- **Claude** ([`dev/claude/`](dev/claude/)): Isolated Claude state with MCP server integration

**Claude Development Environment:**
- **State Isolation**: SHA-256 hash-based state directories
- **MCP Integration**: Sequential-thinking server built from source
- **Auto-configuration**: Automatic `.mcp.json` generation
- **Project Awareness**: Maintains working directory context

### Custom Package Management

**Custom Packages** ([`pkgs/`](pkgs/)):

**alias-teacher** ([`pkgs/alias-teacher/`](pkgs/alias-teacher/)):
- Enhanced fork of zsh-you-should-use
- Improved alias discovery and matching algorithm
- Finds most specific alias matches
- Shows related aliases for command discovery

**mysides** ([`pkgs/mysides/`](pkgs/mysides/)) - Darwin only:
- macOS Finder sidebar management
- Programmatic sidebar item manipulation

**Integration Pattern:**
- Platform-conditional packages in flake overlays
- Automatic integration into user environments
- Proper metadata and licensing information

### Configuration Management Patterns

**Nix Configuration Principles:**
1. **Immutable Taps**: Homebrew taps managed as flake inputs
2. **XDG Compliance**: Consistent use of XDG base directories
3. **Performance Optimization**: Build parallelization, cache configuration
4. **State Management**: Clear separation of mutable and immutable state

**File Organization:**
- **Shared First**: Common configurations in shared modules
- **Platform Overrides**: Platform-specific modules extend shared base
- **User Customization**: User modules for personal preferences
- **Host Specificity**: Minimal host-specific configurations

**Security Considerations:**
- Trusted users configuration for Nix operations
- TouchID integration for system operations
- SSH configuration management
- Secure cache and substituter configuration

**Development Workflow Integration:**
- **Pre-commit Hooks**: Automatic code quality enforcement
- **direnv Integration**: Automatic environment activation
- **Garbage Collection**: Automated cleanup with safety limits
- **Version Pinning**: Flake.lock for reproducible builds

### Shell Environment

ZSH configuration ([`home/modules/shared/cli/zsh/default.nix`](home/modules/shared/cli/zsh/default.nix)):
- **ZIM Framework**: Fast plugin management and initialization
- **Modern CLI Replacements**: eza, bat, fzf, zoxide integration
- **GNU Utilities**: Full GNU toolchain with color support
- **History Management**: XDG-compliant history with enhanced search
- **Alias Discovery**: alias-teacher plugin for command learning (YSU_MODE=ALL)

## Claude Development Environment

The `dev claude` command provides isolated Claude state to prevent project pollution:

1. **Shell Hook** ([`dev/claude/flake.nix:60-110`](dev/claude/flake.nix:60)): Configures isolated environment
2. **State Isolation**: Uses SHA-256 hash of project path for unique state directory
3. **MCP Integration**: Sequential-thinking server built from source
4. **Auto-configuration**: Creates `.mcp.json` on shell entry

Environment variables:
- `CLAUDE_CONFIG_DIR`: Isolated configuration directory
- `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR`: Maintains project directory in shell

State location: `~/.local/state/claude/<project-hash>/`

## Development Workflow

### Pre-commit Hooks

Defined in [`flake.nix:176-187`](flake.nix:176), automatically installed by direnv:
- **nixpkgs-fmt**: Format Nix files
- **statix**: Static analysis and linting
- **deadnix**: Find dead code and unused bindings
- **nil**: Nix language server checks
- **flake-checker**: Validate flake structure and dependencies

### Quality Assurance

**Automated Checks:**
- Pre-commit hooks run on every commit
- `nix-check` command runs full flake validation
- Automatic formatting with nixpkgs-fmt
- Static analysis with statix and deadnix

**Performance Monitoring:**
- `nix-store-size` for disk usage tracking
- Automatic store optimization
- Garbage collection with configurable limits

## Important Notes

- Always run `direnv allow` after cloning to load environment
- Homebrew taps are immutable and managed by Nix
- Weekly auto-GC configured, manual cleanup rarely needed
- Use `nix-check` before commits to ensure code quality
- State isolation prevents project pollution in development environments
- XDG base directories used throughout for consistent file organization