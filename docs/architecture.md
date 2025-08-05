# Nix-Config Architecture

What this actually is and how it works - for AI agents and future me

## The Big Picture

This is my personal Nix configuration that makes my Mac reproducible. After the initial setup dance (installing Nix, configuring it, first build), I can rebuild my entire system with one command. But the real magic? Seamless per-project environment switching with direnv - just `cd` into a project and boom, right tools, right versions, no conflicts.

Built this over 100+ hours and it shows - it's complex but works brilliantly for daily use.

### System vs Project Scope

**System Scope** (one-time setup):
Requires Nix with flakes, Xcode CLI tools, and initial system build. See README.md for setup instructions.

Only AFTER this setup do you get the magic.

**Project Scope** (daily use):

- Per-project `flake.nix` with direnv
- Pre-commit hooks via this repo's `.envrc`
- Development shells in `dev/`

**This Project's Scope**:

- Has its own `.envrc` that loads when you `cd` here
- Installs pre-commit hooks for Nix files
- Provides the `nix-rebuild-host` aliases

## How It's Built

### Core Architecture

```bash
flake.nix                # The brain - defines everything
├── hosts/darwin/        # System-level Mac stuff
│   ├── shared/          # Common config (Nix, Homebrew, security)
│   ├── macbook/         # My M2 MacBook
│   └── parallels-vm/    # Testing VM
├── home/
│   ├── modules/         # Where the magic happens
│   │   ├── shared/      # Cross-platform (80% of everything)
│   │   ├── darwin/      # Mac-specific (Colima, etc)
│   │   └── linux/       # Exists but unused
│   └── users/           # Per-user tweaks
└── pkgs/                # My custom packages
```

**The Stack:**

- `nix-darwin` - Controls macOS settings
- `home-manager` - Manages user environment  
- `nix-homebrew` - GUI apps (browsers, telegram, etc)
- `direnv` - Auto-loads project environments

**Design Philosophy:** Three-tier module system (shared → platform → user). Sounds fancy but just means I write things once and reuse everywhere. 80% shared, 20% platform-specific.

### What Makes It Tick

**Entry Points:**

- `flake.nix` - Start here, defines two systems (macbook, parallels-vm)
- `.envrc` - Auto-loads the Nix environment when you enter the directory
- `hosts/darwin/shared/default.nix` - Common system config
- `home/modules/shared/` - Where most configuration lives

**Builder Functions:**

- `mkDarwinSystem` Builds a complete Darwin system
- `mkHomeManagerConfig` Sets up user environment

## The Good Parts

### What Works Great

**Project Isolation:** This is THE killer feature. Each project gets its own environment:

```bash
cd ~/projects/rust-thing   # Suddenly I have Rust 1.75
cd ~/projects/go-api       # Now I have Go 1.21
# No global installs, no conflicts, just works
```

**Modern CLI:** Replaced all the crusty Unix tools:

- `eza` instead of `ls` (colors! icons! git status!)
- `bat` instead of `cat` (syntax highlighting!)
- `ripgrep` instead of `grep` (blazing fast)
- `fd` instead of `find` (intuitive syntax)

**Custom Tools:**

- `alias-teacher` - Tells me when I type a command that has an alias
- `mysides` - Manages Finder sidebar programmatically

**Automation:**

- Weekly garbage collection keeps Nix store under control
- TouchID for sudo (no more typing passwords)
- Pre-commit hooks keep code clean

### Daily Commands That Matter

```bash
# What I actually use
nix-rebuild-host    # Apply changes to my Mac
nix-update          # Update everything
nix-cleanup         # Free up disk space

# Per-project magic (happens automatically)
direnv allow        # Trust a project's .envrc
```

## The Messy Parts

### Complexity Hot Spots

**1. Theming System** (`home/modules/shared/cli/themes/`)

Way over-engineered. Each tool wants colors differently:

- iTerm2 needs XML plists
- ZSH wants ANSI codes  
- Bat uses tmTheme format

So I built this whole dynamic loading system that generates everything from one color scheme. Works, but yikes.

**2. ZSH + ZIM Integration** (`home/modules/shared/cli/zsh/`)

Three systems fighting over the same config:

- Home-manager wants to control `.zshrc`
- ZIM wants its own `.zimrc`
- I want my customizations

Result: Complex merge logic that mostly works but makes changes painful.

### Technical Debt

**Things that bug me:**

- Those dev shells in `dev/` - never use them, always create per-project flakes
- 50GB Nix store - not really a problem but feels excessive

**Weird Workarounds:**

- Homebrew taps are immutable (managed by Nix) - can't `brew tap` anymore
- Theme loading is fragile - wrong import order = broken colors
- Custom ZIM plugins need manual wiring

## Current Issues

### 1. Colima Memory Bug (`home/modules/darwin/colima/`)

Docker/Kubernetes on Mac via Lima VMs. Config shows 16GB RAM but only gets 2GB. Haven't figured out why yet.

**What:** Configured for 16GB, only gets 2GB
**Where:** `home/modules/darwin/colima/configs/docker.yaml:27331`
**Impact:** Can't run memory-hungry containers

Debugging steps:

```bash
colima status                    # Check current allocation
docker info | grep Memory        # Verify from Docker's view
colima delete && colima start    # Nuclear option
```

### 2. Configuration Complexity

The home-manager integrations are getting out of hand. Every tool wants to be configured differently and home-manager tries to abstract over everything. Maybe just use dotfiles for simple configs?

## Future Ideas

### Things I Want to Try

**Better Project Templates:**
Since I create `flake.nix` for every project anyway:

- Extract the patterns I keep copy-pasting
- Make proper `nix flake init` templates
- Stop reinventing the wheel

**Config DNA Analysis:**
Track what I actually use:

```bash
# Which commands do I run most?
history | awk '{print $1}' | sort | uniq -c | sort -rn

# Which aliases am I ignoring?
# Monthly report: "You haven't used X in 6 months"
```

**Simplification Experiments:**

- Try dotfiles for simple configs (.gitconfig, etc)
- Do I really need home-manager for everything?
- Flatten the module structure?

**Decision Journal:**

Start `decisions.md` to track why I add things:

```markdown
## 2024-01-15: Added lazygit
Trigger: Complex rebase took 30min
Why: Interactive UI beats CLI for conflicts  
Impact: Rebases now ~5min
```

### Maybe Someday

- Share Nix store between host and VMs (save space)
- Actually implement Linux support (structure is ready)
- Extract alias-teacher as its own project
- Optimize Nix evaluation time

## For AI Agents

**Testing changes:**

```bash
nix flake check              # Run all checks
nix-rebuild-host --dry-run   # Test build
direnv reload                # Verify environment
```

Remember: This is a living system that I use daily. Stability > perfection.

---
