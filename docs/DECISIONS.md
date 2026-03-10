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

## 005: From monolithic flake to dendritic flake-parts + import-tree

**What sparked this:** The monolithic `flake.nix` had grown to ~300 lines with hand-rolled `forAllSystems`/`genAttrs`, `nixpkgsFor`, `mkDarwinSystem`, `mkHomeManagerConfig`, overlays, and perSystem assembly all in one file. Adding anything meant scrolling through unrelated code. Wanted a modular structure where each concern lives in its own file.

**The journey:** This was a multi-step evolution, not a single refactor. Each step revealed problems with the previous approach.

**Step 1 — Adopt flake-parts:** Replaced the manual `forAllSystems` boilerplate with `flake-parts.lib.mkFlake` and `perSystem`. This alone eliminated ~50 lines of plumbing. The `treefmt-nix` and `git-hooks.nix` flakeModules auto-wire `formatter` and `checks` — things we were doing by hand.

**Step 2 — Add import-tree (dendritic pattern):** Studied three reference implementations (Doc-Steve, drupol, GaetanLepage). Split the monolith into ~8 files under `modules/`. Added `import-tree` so every `.nix` file is auto-discovered. `flake.nix` became one line: `inputs.import-tree ./modules`.

Initially cargo-culted the Gaetan-style "wrapper pattern" — standard NixOS/HM modules in `_`-prefixed directories (hidden from import-tree), with thin flake-parts wrappers exposing them as `flake.modules.*`. This meant every module was two files: a wrapper and the real implementation.

**Step 3 — Realize wrappers were wrong:** Every edit required touching two files. Questioned: do we need the `_`-prefix convention at all? Turns out `flake.modules.homeManager.foo = { ... }` works inline in a flake-parts module — no need for a separate "standard" module. The whole two-layer pattern was cargo-culted from reference repos that had NixOS configs with different constraints.

**The hard parts:**

1. **specialArgs rabbit hole** — The builder passed `inputs`, `self`, `hostname` via `specialArgs` and `extraSpecialArgs` so darwin/HM modules could access them. Traced every usage and discovered they were ALL already available through flake-parts closures. The darwin module file captures `inputs` in its outer scope (the flake-parts module args), so the inner darwin module never needed specialArgs. Removing this was the biggest "aha" — zero specialArgs remain.

2. **Where do overlays belong?** — Had overlays in a custom `_module.args.nixpkgsOverlays` passed through the builder. Realized `flake.overlays.default` is a standard flake output consumed by `nixpkgs.overlays` in the darwin system config AND `perSystem`. No custom plumbing needed.

3. **User module confusion** — Had three separate options: `users` (list of usernames), `homeManagerModules` (shared HM modules), `userHomeManagerModules` (per-user HM modules). Nobody could tell them apart. Collapsed into one: `users = attrsOf (listOf deferredModule)` where keys are usernames and values are per-user modules. Default modules baked into the builder.

4. **Tried to co-locate users with hosts** — Wanted user config files inside host directories. Hit import-tree constraint: it discovers ALL `.nix` files recursively. Tried `_` prefix (hidden but ugly), tried data-only folders (import-tree ignores non-`.nix` files, but then config must be inline). Accepted that `modules/users/` as a separate directory is the right trade-off.

5. **Dev tooling partition** — Cloned the flake-parts repo itself to study how they isolate dev dependencies. Their `dev/` has its own `flake.nix` + `flake.lock`, and `partitions.nix` routes `devShells`/`checks`/`formatter` to that scope. Copied the pattern directly. System evaluation (`darwinConfigurations`) no longer fetches pre-commit-hooks, treefmt-nix, or nix-filter. One gotcha: statix complained about repeated attribute keys — `partitionedAttrs` needed to be a single attrset, not separate assignments.

6. **`mkPkgs` and meta indirection** — Had a `mkPkgs` helper function and `meta.nix` with a loose `attrsOf unspecified` type just for `systemAdmin.username`. Replaced `mkPkgs` with native `nixpkgs.overlays` + `nixpkgs.config.allowUnfree` in the darwin system config. Inlined `systemAdmin` as a let binding. Deleted both files.

7. **spotlight coupling** — `spotlight.nix` reached into `config.home-manager.users` to discover usernames. Decoupled it by adding an explicit `spotlight.users` option set by the builder.

**What we learned:**

- **specialArgs is a code smell in flake-parts.** If you're passing inputs/self via specialArgs, you probably already have them in the module closure. Check before adding plumbing.
- **Question every indirection.** `mkPkgs` helper, `meta.nix` module, `_module.args.nixpkgsOverlays` — all replaced by standard Nix patterns (`nixpkgs.overlays`, `flake.overlays.default`, let bindings). If a helper only exists to pass data between two places, there's probably a direct way.
- **YAGNI for infra too.** Removed parallels host/user, Linux modules. The config pretended to support multi-user/multi-platform when it didn't. Kept `aarch64-linux` in systems only because the devcontainer needs it.
- **Evolve incrementally, don't design upfront.** Each step (flake-parts → import-tree → flatten) was informed by pain from the previous step. If we'd tried to design the final structure upfront, we'd have gotten it wrong.

**Future Me Notes:** Every `.nix` file in `modules/` is auto-discovered. Non-`.nix` files (configs, plists, yaml) are ignored by import-tree. Adding a module = create one file. If you need multi-user back, it's ~20 minutes of work on the builder. Don't pre-build infrastructure for hypotheticals.

---
