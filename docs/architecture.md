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
│   └── darwin/                # macOS-specific: brew, colima
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

That inline form works only while the aggregated module is a plain attrset. One that is a FUNCTION taking
`config` — home-manager's — must bind the flake's `config` in an enclosing `let` instead:

```nix
# modules/users/happygopher/darwin.nix
{ config, ... }:
let
  inherit (config.flake.modules.homeManager) happygopher-identity;
in {
  flake.modules.homeManager.happygopher-darwin =
    { config, lib, pkgs, ... }: {      # <- shadows the flake's `config`
      imports = [ happygopher-identity ];
    };
}
```

Reaching for `config.flake…` inside that function is not a wrong value, it is `error: infinite recursion
encountered` — `imports` may never reference the module's own `config`.

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
- home-manager with default modules (core, cli, development, darwin-brew, darwin-colima)
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

Isolated development shells via [nix-devx](https://github.com/screwyprof/nix-devx):
- **go**, **rust**, **nix**, **claude**, **claude-unrestricted**, **bmad-method** — Ad-hoc shells from nix-devx
- Entered via `dev <name>` shell function (wraps `nix develop` with nix-devx)
- Set `NIX_DEVX` env var for local clone path, otherwise fetches from GitHub
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

## Nix Profiles and Generations

Understanding how profiles and generations work in this setup is important because it differs from a vanilla NixOS + home-manager configuration.

### How It Works on NixOS (for comparison)

On NixOS with home-manager as a **standalone tool**, there are two independent profile chains:

| Profile | Path | Managed by |
|---|---|---|
| System | `/nix/var/nix/profiles/system` | `nixos-rebuild switch` |
| Home Manager | `~/.local/state/nix/profiles/home-manager` | `home-manager switch` |

Each has its own numbered generations and independent rollback. You can rebuild user config without touching the system and vice versa.

### How It Works Here (nix-darwin + integrated home-manager)

In this setup, home-manager runs as a **nix-darwin module** (via `home-manager.darwinModules.home-manager` in `builder.nix`). This means there is only one build entry point: `darwin-rebuild switch`.

**Key settings in `builder.nix`:**
- `useGlobalPkgs = true` — HM uses the system's nixpkgs instance instead of its own, avoiding duplicate evaluations
- `useUserPackages = true` — HM packages install to `/etc/profiles/per-user/$USER` (system-managed) instead of `~/.nix-profile`

**Profile paths:**

| Profile | Path | Contents |
|---|---|---|
| System | `/nix/var/nix/profiles/system` | Full system + HM activation, numbered generations (`system-1-link`, `system-2-link`, ...) |
| System (current) | `/run/current-system` | Symlink to the active system generation |
| User packages | `/etc/profiles/per-user/<username>` | HM-managed packages (due to `useUserPackages = true`) |
| HM gcroot | `~/.local/state/home-manager/gcroots/current-home` | Symlink to the current HM generation in `/nix/store`, prevents GC collection |

**What does NOT exist in this setup:**
- `~/.local/state/nix/profiles/home-manager` — no standalone HM profile with numbered generations
- `/nix/var/nix/profiles/per-user/<username>` — no per-user profile directory (only `root` has one)
- `~/.nix-profile` — not used because `useUserPackages = true`

### Generations and Rollback

Every `darwin-rebuild switch` creates a new **system generation** that includes both system config and the home-manager activation. There are no separate HM generations.

```bash
# List system generations (includes HM changes)
nix profile history --profile /nix/var/nix/profiles/system

# Rollback system + HM together
darwin-rebuild switch --rollback
```

The HM gcroot (`~/.local/state/home-manager/gcroots/current-home`) points to the current HM generation store path but only tracks the latest — no history. This gcroot exists solely to prevent garbage collection of the active HM closure.

### Why Not Build Home-Manager Separately?

Since HM is integrated as a darwin module, adding a standalone `homeConfigurations` output would create **two profiles managing the same dotfiles** — the integrated one (via `darwin-rebuild`) and the standalone one (via `home-manager switch`). Their activation scripts would conflict.

In practice, `darwin-rebuild switch` is fast enough (~1 min) that maintaining a separate HM build path isn't worth the complexity and risk.

### Summary

```
darwin-rebuild switch
        │
        ├── System activation
        │   ├── Nix daemon config
        │   ├── Homebrew (casks, brews, MAS apps)
        │   ├── PAM (TouchID for sudo)
        │   ├── environment.profiles (PATH)
        │   └── Spotlight app launchers
        │
        └── Home-Manager activation (per user)
            ├── Dotfiles (~/.zshrc, ~/.config/*, ...)
            ├── Packages → /etc/profiles/per-user/<username>
            ├── Shell config (zsh, fzf, bat, eza, ...)
            ├── Dev tools (git, direnv, node, python, ...)
            ├── macOS user defaults (keyboard, dock, finder)
            ├── App profiles (iTerm2, Terminal.app)
            └── gcroot → ~/.local/state/home-manager/gcroots/current-home
```

## Pre-commit Hooks

Enforced via the dev partition:
- **nixfmt** — Code formatting
- **statix** — Anti-pattern detection
- **deadnix** — Unused binding detection
- **nil** — Language server diagnostics
- **flake-checker** — Flake health validation
