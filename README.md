# nix-config

Personal Nix configuration for macOS using Nix Flakes, nix-darwin, home-manager, and nix-homebrew.

**Quick Links:**
- [Architecture Documentation](docs/architecture.md) - Technical patterns and system organization
- [Decision Journal](docs/DECISIONS.md) - Chronological record of significant changes

---

## What & Why

**Problem**: Setting up new dev machines is tedious and error-prone. Installing 50+ tools, recreating years of customizations, dealing with version conflicts between projects. Every setup takes 4-8 hours and something is always forgotten.

**Solution**: This nix-config uses Nix flakes to make my entire system reproducible. One command sets up everything exactly how I like it. Projects get isolated environments via `direnv + nix`, so no more "works on my machine" issues.

**Reality Check**: I only set up 2-3 new machines per year, but I switch between projects daily. The real win is seamless project environment switching and fearless experimentation.

## Architecture

See [`docs/architecture.md`](docs/architecture.md) for technical details.

## What's Included

**CLI Tools** (50+):
- Modern replacements: `eza` (ls), `bat` (cat), `fd` (find), `ripgrep` (grep)
- Shell: ZSH with ZIM framework, Powerlevel10k prompt
- Dev tools: Git with delta, fzf everywhere, direnv
- Custom packages: `alias-teacher` (helps learn my own aliases), `mysides` (Finder sidebar management)

**Development Environments**:
- Go/Rust/Claude dev shells via [nix-devx](https://github.com/screwyprof/nix-devx) (`dev <name>` wrapper)
- Project isolation via `direnv + flake.nix` (this is the real magic)
- Pre-commit hooks, formatters, linters

**System Features**:
- TouchID for sudo
- Weekly garbage collection
- Unified theming (Dracula via base24)
- GNU utils prepended to PATH (sanity on macOS)

**Via Homebrew** (nix-homebrew manages these):
- GUI apps: Bitwarden, Firefox, iTerm2, JetBrains Toolbox, etc.
- Mac App Store: Bear, Noir, AdGuard for Safari

## Commands I Actually Use

```bash
# System management
nix-rebuild-host      # Rebuild macbook
nix-check             # Run flake checks + pre-commit hooks
nix-update            # Update all flake inputs
nix-fmt               # Format Nix files
nix-cleanup           # Garbage collect + optimize

# Development (via nix-devx)
dev go                # Go dev shell
dev rust              # Rust dev shell
dev claude            # Claude + MCP servers (restricted)
dev claude-unrestricted  # Claude + MCP (skip permissions)

# Set NIX_DEVX=/path/to/nix-devx for local clone, otherwise fetches from GitHub
# Reality: I just create flake.nix per project
# Just cd into any project with flake.nix and direnv does the rest
```

## Honest Trade-offs

**Accepted**:
- 50GB Nix store — Complete reproducibility
- High complexity — But AI makes it manageable now
- macOS-only — Optimized for what I actually use
- Some maintenance time — Worth it for daily productivity
- ~10min rebuilds — Acceptable for full system updates

**Rejected**:
- Cross-platform purity (this is macOS-only)
- Team-friendly (this is MY config, use at your own risk)
- Minimal/simple (I want all my tools configured perfectly)

## Lessons Learned

1. **Complexity creeps**: Each tool integration led to another
2. **Documentation matters**: Git commits aren't enough context
3. **Perfection trap**: Some things are good enough
4. **AI changes everything**: Nix complexity less scary with Claude — this is THE game changer that makes Nix viable for personal use
5. **YAGNI applies to infra too**: Multi-user, multi-platform support removed when not actually used

## Technical Choices Worth Remembering

- **ZIM over Oh-My-Zsh**: Performance matters when you live in the terminal
- **nix-darwin + home-manager**: System + user separation is worth the complexity
- **direnv**: The magic that makes project switching seamless
- **Weekly GC**: Automated via launchd, keeps store from growing infinitely
- **Flake-parts partitions**: Dev tooling doesn't slow down system evaluation

---

*This README is for future me who's forgotten how everything works. Hi future me! The answers you seek are in the git history, AI assistants, and that `docs/DECISIONS.md` file you hopefully created. Don't overthink it.*
