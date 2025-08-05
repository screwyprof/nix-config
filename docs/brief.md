# nix-config Project Brief

## What & Why

**Problem**: Setting up new dev machines is tedious and error-prone. Installing 50+ tools, recreating years of customizations, dealing with version conflicts between projects. Every setup takes 4-8 hours and something is always forgotten.

**Solution**: This nix-config uses Nix flakes to make my entire system reproducible. One command sets up everything exactly how I like it. Projects get isolated environments via `direnv + nix`, so no more "works on my machine" issues.

**Reality Check**: I only set up 2-3 new machines per year, but I switch between projects daily. The real win is seamless project environment switching and fearless experimentation.

## Architecture

```bash
flake.nix
├── hosts/darwin/         # Machine-specific configs
│   ├── macbook/          # Main M2 machine
│   └── parallels-vm/     # Testing VM
├── home/
│   ├── modules/shared/   # Cross-platform stuff
│   ├── modules/darwin/   # macOS-specific
│   └── users/darwin/     # Per-user configs
└── pkgs/                 # Custom packages
```

**Core Stack**:

- `nix-darwin`: System-level macOS configuration
- `home-manager`: User environment management  
- `nix-homebrew`: GUI apps via Homebrew
- `flakes`: Reproducible, modern Nix

**Design**: Three-tier module system keeps things DRY. Target: 80% shared modules, 20% host-specific. XDG-compliant paths. Immutable Homebrew taps via flake inputs. No secrets in configs.

## What's Included

**CLI Tools** (50+):

- Modern replacements: `eza` (ls), `bat` (cat), `fd` (find), `ripgrep` (grep)
- Shell: ZSH with ZIM framework, Powerlevel10k prompt
- Dev tools: Git with delta, fzf everywhere, direnv
- Custom packages: `alias-teacher` (helps learn my own aliases), `mysides` (Finder sidebar management)

**Development Environments**:

- Go/Rust dev shells in `dev/` (unused - I create per-project flakes)
- Claude shell (experimental MCP integration via .envrc)
- Project isolation via `direnv + flake.nix` (this is the real magic)
- Pre-commit hooks, formatters, linters

**System Features**:

- TouchID for sudo
- Weekly garbage collection
- Unified theming (base24/base16)
- Automated updates via `nix-update` alias

**Via Homebrew** (nix-homebrew manages these):

- GUI apps: browsers, telegram, table-plus, etc..
- AppleStore apps: Bear, Noir, etc...
- Anything that works better with Homebrew

## Honest Trade-offs

**Accepted**:

- 🗄️ 50GB Nix store → Complete reproducibility
- 🧩 High complexity → But AI makes it manageable now
- 🍎 macOS-only → Optimized for what I actually use
- ⏰ Some maintenance time → Worth it for daily productivity
- 🚀 ~10min rebuilds → Acceptable for full system updates

**Rejected**:

- Cross-platform purity (Linux support is scaffolded but unused)
- Team-friendly (this is MY config, use at your own risk)
- Minimal/simple (I want all my tools configured perfectly)

## Commands I Actually Use

```bash
# System management
nix-rebuild-host      # Rebuild current machine (macbook)
nix-rebuild-mac       # Rebuild parallels VM
nix-check            # Run flake checks + pre-commit hooks
nix-update           # Update all flake inputs
nix-fmt              # Format Nix files
nix-cleanup          # Garbage collect + optimize

# Development
dev go               # Go dev shell (never used)
dev rust             # Rust dev shell (never used) 
dev claude           # Claude + MCP servers (testing)

# Reality: I just create flake.nix per project
# Just cd into any project with flake.nix and direnv does the rest
```

## Current Pain Points

1. **Colima memory allocation**: Configured for 16GB but only gets 2GB - blocking container development
2. **Home-manager complexity**: Every integration is complicated (theming, ZSH/ZIM)
3. **Documentation**: Future me will forget why I added things

## Future Explorations

**Near-term Fixes**:

- **Fix Colima**: Debug why memory allocation isn't working
- **Dotfiles investigation**: Should home-manager just install software while dotfiles handle config?

**Near-term Experiments**:

- **Dev shells usage**: Actually try using `dev go/rust` for 3rd party projects without Nix
- **Better templates**: Since I create flake.nix for every project anyway:
  - Extract common patterns
  - Build real `nix flake init` templates
  - Stop reinventing the wheel each time
- **Documentation**: Add decision comments inline when adding tools

**Configuration Chronicle** (The interesting part):

- **Config DNA Analysis**:

  ```bash
  # Parse shell history for actual usage
  history | awk '{print $1}' | sort | uniq -c | sort -rn
  # Track which aliases get used vs ignored
  # Monthly report: "You haven't used X in 6 months"
  ```

- **Decision Journal** (`decisions.md`):

  ```markdown
  ## 2024-01-15: Added lazygit
  Trigger: Complex rebase took 30min
  Why: Interactive UI beats CLI for conflicts
  Impact: Rebases now ~5min
  ```

- **Usage Patterns**: Which tool combinations always appear together?

**Architecture Questions**:

- Is three-tier module system overkill? Try flatter structure
- Can we reduce Nix evaluation time?
- Bridge system config ↔ project configs better

**Maybe Someday**:

- Shared Nix store between host/VMs (save space)
- Linux support (keep architecture ready, just in case)
- Extract alias-teacher as standalone project

## Lessons Learned

1. **Complexity creeps**: Each tool integration led to another
2. **Documentation matters**: Git commits aren't enough context
3. **Perfection trap**: Some things are good enough
4. **AI changes everything**: Nix complexity less scary with Claude/GPT - this is THE game changer that makes Nix viable for personal use

## Technical Choices Worth Remembering

- **ZIM over Oh-My-Zsh**: Performance matters when you live in the terminal
- **nix-darwin + home-manager**: System + user separation is worth the complexity
- **direnv**: The magic that makes project switching seamless
- **Weekly GC**: Automated via launchd, keeps store from growing infinitely

## Risks & Mitigations

**What could break**:

- macOS updates changing security → Nix community will adapt
- Nix ecosystem churn → Pin known-good versions
- Tool abandonment → Find alternatives or remove

**When returning after time away**:

1. Read this doc first
2. Check `decisions.md` for context
3. `git log --oneline` for recent changes
4. Ask AI to explain confusing Nix expressions

## Key Decisions & Why

**Why Nix over dotfiles/scripts**:

- "In the past I had rust, golang, haskell globally installed, now I can pick the right tools for the right project" - Project isolation is THE killer feature
- Daily value: "I just cd to the project and direnv + nix will do the rest"

**Why accept the complexity**:

- "It made my life easier... too time consuming to set up the environment and make it eye-pleasing and functionally rich"
- The 100+ hours are already spent and paid back
- AI tools now make debugging Nix approachable

**Why this architecture**:

- Modular approach allows future Linux support "without drastic changes"
- Three tiers emerged naturally from refactoring, not over-engineering
- "I patched a lot of tools to my taste" - customization matters

**Why document decisions**:

- "Maybe a good idea... to capture thought process"
- Git commits aren't enough - need the "why"
- Future me needs context, not just code

## Real Talk

This project is **constantly evolving**. It works brilliantly for my needs. Yes, it's complex. Yes, it took 100+ hours to build. But it makes daily development a joy and lets me experiment fearlessly.

Future work should focus on:

- Simplifying what's already there
- Documenting the "why" not just the "what"  
- Measuring actual tool usage (Config DNA)
- Better project initialization (stop recreating flakes)
- Resisting feature creep (but embracing useful evolution)

Remember: This serves daily productivity, not architectural purity.

---

*This brief is for future me who's forgotten how everything works. Hi future me! The answers you seek are in the git history, AI assistants, and that decisions.md file you hopefully created. Don't overthink it.*