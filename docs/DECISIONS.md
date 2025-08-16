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

## 004: GC Deleting In-Use Shell Configurations

**What sparked this:** After weekly GC runs, zsh prompts to reconfigure p10k and all settings in `~/.config/zsh/` are lost. Previous fix (commit d1f2e635c) adding `use-xdg-base-directories = true` didn't work.

**The journey:** Initially thought root's GC couldn't see user profiles. Added XDG setting thinking it would help. But that only affects Nix's own profiles, not home-manager! Discovered GC CAN see user profiles via `/nix/var/nix/gcroots/auto/`, but...

**The real bug discovered:**

1. Shell loads config from generation 105
2. Many rebuilds later → at generation 150
3. Generation 105 now >30 days old
4. GC deletes it due to `--delete-older-than 30d`
5. **GC roots protect from "unreachable" deletion, NOT age-based!**
6. Home-manager cleanup: `rmdir -p` recursively deletes dirs
7. Takes `.zim/`, `.zcompdump`, all mutable state

**What we learned:**

- `use-xdg-base-directories` ≠ home-manager profile visibility
- GC roots don't override `--delete-older-than`
- With 105+ generations, you rebuild frequently
- Long-running shells reference old generations
- Home-manager cleanup is aggressive with `-p`

**Outcome:** Multiple solutions identified. Short-term: move mutable state to `~/.local/state/zim`. Better: remove age-based GC or use `--keep-generations`. Created detailed analysis in `docs/ideas/nix-gc-removes-current-settings.md`.

**Future Me Notes:** When shells lose config after GC, check generation count! High numbers = frequent rebuilds = old generations deleted while in use. GC roots only prevent "unreachable" deletion, not age-based cleanup.

---

## 005: BMad Workflow Experience - Lessons from Real Usage

**What sparked this:** Used `BMad` `v4.35.3` to investigate the `nix-gc` issue mentioned in decision `#004`. First real test of `BMad` on existing codebase revealed both strengths and significant limitations.

**The journey:** Applied full `BMad` workflow: Analyst → PM → PO → SM → Dev. Created brief, PRD, and stories. Hit multiple friction points requiring workarounds.

**Key discoveries:**

1. **Exceptional elicitation** - Best requirements gathering techniques found in years
2. **Monolithic documentation** - One giant PRD/Brief for entire system (can't do feature-based work)
3. **Workflow blockers** - Stories stuck at "Draft", no approval mechanism
4. **Agent isolation** - User becomes the workflow engine, manually coordinating everything
5. **No feature concept** - Can't trace work from idea to implementation (generic story names like `1.1.story.md`)

**Workarounds developed:**

- Created feature-specific paths (`docs/briefs/[feature].md`)
- Added manual handoff prompts to PRD for agent coordination
- Skipped Architect for investigation work
- Manually updated story statuses after PO validation

**Outcome:** Successfully structured the `nix-gc` investigation using `BMad` workflow. Created initial feedback at `docs/ideas/bmad-feedback.md` documenting the experience and limitations discovered. The two core issues: no central coordination and no feature-driven approach. Planning to share this feedback with the `BMad` community.

**Future Me Notes:** `BMad` excels at structured thinking but assumes greenfield monolithic projects. For feature work or investigations, expect to create many workarounds. The elicitation techniques alone make it valuable, but don't expect smooth multi-feature workflows.

---
