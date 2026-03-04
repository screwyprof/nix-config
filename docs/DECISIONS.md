# Decision Journal

A chronological record of decisions made in `nix-config`, capturing what sparked each change, the journey to solution, and lessons learned.

---

## 001: BMad Integration

**What sparked this:** Needed a structured approach to AI-assisted development but kept getting lost in complex work without clear workflow.

**The journey:** Started exploring various AI agent frameworks. Found [BMad-Method](https://github.com/bmadcode/BMAD-METHOD) which provides clear agent roles (Analyst, PM, Architect, Dev, etc..) and workflows for both new projects and existing codebases.

**What we tried:**

1. Ad-hoc AI assistance → Too unstructured, kept losing context
2. Custom agent definitions → Too much work to maintain
3. `BMad-Method` → Perfect balance of structure and flexibility

**Outcome:** Packaged `BMad` as nix derivation for `v4.34.0`, integrated into development flow in this project. Now have systematic approach to complex work.

**Future Me Notes:** When tackling complex tasks, start with BMad agents for structured brainstorming. Don't use all agents for simple tasks - that's overkill.

---

## 002: Update BMad to v4.35.3

**Context:** Wanted to update BMad to latest version (`v4.35.3`). Changed the version field but kept old hashes. Rebuild succeeded but was still running old version! This revealed a confusing `buildNpmPackage` behavior where updating version without hashes silently serves cached content.

**The Plot Twist:** Changed version to `v4.35.3` but rebuild gave old version! In `buildNpmPackage`, the hash determines what gets fetched - version is just metadata.

**What we learned:**

- `buildNpmPackage` has TWO hashes: source hash and `npmDepsHash`
- Both must be updated when version changes
- Old hash = old content, regardless of version string  
- No warnings when version/hash mismatch - just wrong version
- Nix store caching made it seem like build "worked"

**Outcome:** Fixed BMad hashes to properly update from `v4.34.0` to `v4.35.3`. Used `nix-prefetch-github` for source hash and `lib.fakeHash` technique for `npmDepsHash`. Created our first idea document at `docs/ideas/nix-package-version-hash-mismatch.md` to explore ways to prevent this confusing behavior in the future.

**Future Me Notes:** For NPM packages: Always use `lib.fakeHash` for BOTH hashes when updating versions! The silent failure is the worst part - you think you updated but didn't. We should think about improving this process.

---

## 003: Package markdown-tree-parser for BMad sharding

**Context:** While investigating `BMad`'s document sharding feature (`*shard-doc`), discovered it expects `md-tree` command to be available but doesn't provide it. BMad assumes users will install `@kayvan/markdown-tree-parser` globally via npm.

**The Discovery:** Found in `.bmad-core/tasks/shard-doc.md` that BMad checks for `markdownExploder: true` in config, then tries to run `md-tree explode` command. Without this tool, BMad falls back to manual sharding.

**What we tried:**

1. Check if `BMad` bundles the tool → No, it expects global install
2. Look for alternative → None, BMad specifically needs `md-tree`
3. Package it in Nix → Success! Provides exact command BMad expects

**Outcome:** Created Nix package for markdown-tree-parser `v1.6.0`, added to flake overlays, included in `ai-tools.nix`. Now BMad's sharding works seamlessly without manual npm installs.

**Future Me Notes:** This makes `BMad` more self-contained in our Nix environment. The `md-tree` command is now available system-wide.

---

## 004: Remove BMad Integration

**Context:** After integrating BMad as a Nix package and using it for several months, realized it was overkill for personal workflow. The structured agent approach (Analyst, PM, Architect, Dev, etc.) and extensive workflows were designed for team environments, not solo development.

**The journey:** Initially adopted BMad to bring structure to complex development tasks. Created Nix packages for both BMad (v4.34.0, updated to v4.35.3) and its dependency markdown-tree-parser. However, in practice:

1. **Too much overhead** - Simple tasks didn't need full agent orchestration
2. **Solo workflow mismatch** - Roles like PM, QA, SM designed for teams
3. **Complexity vs benefit** - Setup and maintenance outweighed advantages
4. **Better alternatives** - Direct Claude Code interaction more efficient for solo work

**What we tried:**
1. Full BMad integration with all agents → Too heavyweight for this project
2. Selective agent usage → Still required maintaining entire framework
3. Direct Claude Code usage → Simpler, more effective

**What got removed:**
- `.bmad-core/` directory (96 files): agents, workflows, checklists, templates
- `.claude/commands/BMad/`: BMad slash commands
- BMad-related documentation: `docs/bmad-method.md`

**Outcome:** Streamlined configuration by removing BMad framework entirely.

**Lessons learned:**
- Team-oriented frameworks don't always translate well to solo workflows
- More structure ≠ more productivity for individual developers
- YAGNI principle applies to development tools too
- Better to start simple and add complexity when actually needed

**Future Me Notes:** Don't reinstitute heavy frameworks unless there's a clear, demonstrated need. For personal projects, direct AI interaction with proper planning (when needed) works better than rigid agent systems. If document sharding becomes important, markdown-tree-parser is still available.

---
