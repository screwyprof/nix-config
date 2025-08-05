# CLAUDE.md

Quick reference for AI assistants working with this nix-config.

## Documentation

- **[README.md](README.md)** - Setup and commands
- **[docs/brief.md](docs/brief.md)** - Vision and philosophy
- **[docs/architecture.md](docs/architecture.md)** - Technical details
- **[docs/bmad-method.md](docs/bmad-method.md)** - BMad workflows
- **[docs/DECISIONS.md](docs/DECISIONS.md)** - Decision journal
- **[docs/features/](docs/features/)** - Feature tracking
- **[docs/briefs/](docs/briefs/)** - Feature planning docs

## Key Commands

```bash
# Test before applying
nix-rebuild-host --dry-run

# Apply changes
nix-rebuild-host

# Check code
nix-check
```

## Where Things Live

- Entry point: `flakes.nix`
- System config: `hosts/darwin/`
- User modules: `home/modules/`
- Custom packages: `pkgs/`

Follow the three-tier pattern: shared → platform → user

## Documentation Workflow

1. **Planning**: Create brief in `docs/briefs/` (optional)
2. **Tracking**: Create feature in `docs/features/` with status
3. **Implementation**: Update feature status as you work
4. **Decision**: Add entry to `DECISIONS.md` when complete

Features track evolution, decisions capture the journey.

## Current Issues

1. **Colima**: Configured for 16GB, only gets 2GB
   - Config: `home/modules/darwin/colima/configs/docker.yaml`

2. **Complex integrations**: Theming and ZSH/ZIM are over-engineered
See architecture.md for details.

---

*Read the full docs when you need details. This is just a map.*
