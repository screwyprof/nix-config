# Nix Config Architecture

This document describes the architectural patterns and organization used in this nix-config repository.

## High-Level Structure

This repository uses **Nix Flakes** for reproducible macOS system configuration with:

- **nix-darwin** - System-level macOS configuration
- **home-manager** - User environment management
- **nix-homebrew** - Declarative Homebrew integration for GUI apps
- **flake-parts + import-tree** - Dendritic module system for composable configuration
- **flake-parts partitions** - Dev tooling isolated from system evaluation

## Dendritic Pattern

The configuration uses the **dendritic pattern** with `import-tree`. Every `.nix` file under `modules/` is automatically discovered as a flake-parts module — no manual imports needed.

```
flake.nix                      # Inputs + one-liner: inputs.import-tree ./modules
modules/
├── flake/                     # Flake-parts infrastructure
│   ├── systems.nix            # Supported systems + flake-parts modules import
│   ├── nixpkgs.nix            # Overlays (flake output) + perSystem pkgs/packages
│   └── partitions.nix         # Routes devShells/checks/formatter to dev partition
├── hosts/
│   └── darwin/
│       ├── shared/
│       │   ├── builder.nix    # darwinHosts option + host factory
│       │   ├── system.nix     # All darwin system config (nix, homebrew, sops, etc.)
│       │   └── spotlight.nix  # Spotlight-compatible app launchers
│       └── macbook.nix        # Host declaration
├── home/                      # Home-manager feature modules
│   ├── core.nix               # Aggregator: fonts, gnu-utils, vim, fastfetch, safe-rm
│   ├── cli.nix                # Aggregator: zsh, bat, fzf, cheat, tldr, zoxide, etc.
│   ├── development.nix        # Aggregator: git, nix, direnv, node, python, vscode, etc.
│   ├── core/                  # Core feature modules
│   ├── cli/                   # CLI tool modules
│   ├── dev/                   # Development tool modules
│   └── darwin/                # macOS-specific: brew, colima, coredumps
├── users/
│   └── happygopher/
│       └── darwin.nix         # Per-user config: macOS prefs, git identity, iTerm2, Terminal
dev/                           # Dev partition (separate flake.lock)
├── flake.nix                  # Dev-only inputs: pre-commit-hooks, treefmt-nix, nix-filter
└── flake-module.nix           # Devshell + treefmt + pre-commit config
pkgs/                          # Custom packages + local flakes
├── alias-teacher/             # ZSH alias teaching plugin
├── bmad-method/               # AI agent framework
├── markdown-tree-parser/      # Markdown document parser
├── mysides/                   # macOS Finder sidebar management
├── zim-plugins/               # Custom ZIM plugins
├── zimfw-nix/                 # Local flake: ZIM framework HM module
└── nix-themes/                # Local flake: Terminal theming (Dracula/Gruvbox)
```

### How Modules Work

Every `.nix` file under `modules/` is a flake-parts module. They expose darwin or home-manager modules via `flake.modules.*`:

```nix
# modules/home/dev/git.nix — directly a flake-parts module
{
  flake.modules.homeManager.dev-git = _: {
    programs.git = { ... };
  };
}
```

Aggregator modules compose feature modules:

```nix
# modules/home/development.nix
{ config, ... }: {
  flake.modules.homeManager.development = {
    imports = with config.flake.modules.homeManager; [
      dev-git dev-nix dev-direnv dev-node dev-python dev-vscode dev-claude dev-containers
    ];
  };
}
```

## Host Configuration

Hosts are declared using the `darwinHosts` option defined in `builder.nix`:

```nix
# modules/hosts/darwin/macbook.nix
{ config, ... }: {
  darwinHosts.macbook = {
    users.happygopher = [ config.flake.modules.homeManager.happygopher-darwin ];
  };
}
```

The builder automatically wires up:
- nix-darwin system configuration (system.nix + spotlight.nix)
- home-manager with default modules (core, cli, development, darwin-brew, darwin-colima, darwin-coredumps)
- Per-user home-manager modules merged on top of defaults
- sops-nix, nix-index-database, zimfw-nix, nix-themes integrations

### Users

Users are `attrsOf (listOf deferredModule)` — keys are usernames, values are lists of per-user home-manager modules. The builder creates `users.users`, `home-manager.users`, and `spotlight.users` entries for each.

## Dev Partition

Dev tooling (devshell, treefmt, pre-commit) lives in a separate **flake-parts partition** with its own `flake.lock`. This means `nix eval .#darwinConfigurations.macbook` never fetches dev-only inputs.

- `dev/flake.nix` — declares dev-only inputs (pre-commit-hooks, treefmt-nix, nix-filter)
- `dev/flake-module.nix` — configures treefmt (nixfmt), pre-commit hooks (statix, deadnix, nil, flake-checker), and devShell
- `modules/flake/partitions.nix` — routes `devShells`, `checks`, `formatter` to the dev partition

## Overlay System

Custom packages are exposed as `flake.overlays.default` (defined in `modules/flake/nixpkgs.nix`):

- Composes rust-overlay + custom packages via `lib.composeManyExtensions`
- Platform-conditional packages (e.g., `mysides` is Darwin-only)
- Consumed by both `perSystem` (for `nix build .#package`) and darwin system config (via `nixpkgs.overlays`)

## Theming

Centralized theme management via the `nix-themes` local flake (`pkgs/nix-themes/`):

- **Schemes** — Color definitions (base24-dracula, base16 via nix-colors)
- **Presets** — Map schemes to per-program theme configs
- **Programs** — ZSH (Powerlevel10k + ANSI), bat, iTerm2

Changing the active preset propagates colors across all integrated programs.

## CLI Tools Philosophy

Modern replacements for traditional Unix tools:
- **eza** instead of `ls` — Icons, git integration, tree view
- **bat** instead of `cat` — Syntax highlighting, git integration
- **fd** instead of `find` — Faster, more intuitive
- **ripgrep** instead of `grep` — Faster, better defaults
- **fzf** — Fuzzy finder integrated everywhere (completions, file search, directory nav)
- **zoxide** instead of `cd` — Smart directory navigation
- **moor** instead of `less` — Modern pager with Dracula styling

These are integrated with:
- **ZIM Framework** — Fast ZSH plugin management with priority-ordered module loading
- **Powerlevel10k** — Instant prompt, customizable theme
- **alias-teacher** — Custom ZSH plugin that helps discover and learn aliases
- **fzf-tab** — FZF-powered tab completion with previews (SSH hosts, env vars, directories)

## Development Environments

Isolated development shells in `dev/`:
- **go**, **rust**, **claude**, **bmad-method** — Each is a separate flake with its own dependencies
- Entered via `dev <name>` shell function (wraps `nix develop`)
- In practice, per-project `flake.nix` + `direnv` is used more often

Development tools installed system-wide:
- Git with delta diff viewer, GitHub CLI
- direnv with nix-direnv for automatic environment activation
- Docker via colima (managed by launchd agent)
- Claude Code, VSCode with Nix IDE

## Homebrew Integration

GUI apps managed declaratively via `nix-homebrew` with immutable taps (pinned as flake inputs):
- **Casks**: Bitwarden, Firefox, iTerm2, JetBrains Toolbox, Parallels, TablePlus, etc.
- **Mac App Store** (via `mas`): Bear, Noir, AdGuard for Safari
- `onActivation.cleanup = "zap"` — removes anything not declared

## Custom Packages

- **alias-teacher** — Enhanced ZSH plugin that finds most specific alias matches and shows related aliases for discovery
- **bmad-method** — AI agent framework (BMad-METHOD) packaged as Nix derivation
- **markdown-tree-parser** — NPM package for parsing markdown documents
- **mysides** — macOS Finder sidebar management tool (Objective-C, arm64)
- **zim-plugins** — Custom ZIM framework plugins (enhanced-paste, p10k config)
- **zimfw-nix** — Local flake providing ZIM framework as a home-manager module
- **nix-themes** — Local flake for centralized terminal theming (Dracula/Gruvbox)

## Key Design Decisions

- **No specialArgs/extraSpecialArgs** — All inputs resolve through flake-parts closures
- **GNU utils prepended to PATH** — Explicit PATH ordering in zsh.nix guarantees GNU tools shadow macOS BSD equivalents
- **fzf integration disabled in HM** — Keybindings sourced manually after zim init for correct fzf-tab ordering
- **Immutable Homebrew taps** — Managed as flake inputs for reproducibility
- **XDG compliance** — All configurations use XDG base directories
- **TouchID for sudo** — Configured via nix-darwin PAM

## Pre-commit Hooks

Enforced via the dev partition:
- **nixfmt** — Code formatting
- **statix** — Anti-pattern detection
- **deadnix** — Unused binding detection
- **nil** — Language server diagnostics
- **flake-checker** — Flake health validation
