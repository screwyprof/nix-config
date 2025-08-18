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

## 006: Story 1.1 - Bug Reproduction Success & BMad QA Agent

**What sparked this:** Completed Story 1.1 for nix-gc bug reproduction using BMad agents. Also updated bmad-feedback-public.md with Dev agent issues discovered during implementation.

**The journey:** Applied BMad Dev agent (James) to implement Story 1.1. Successfully captured all terminal configuration state before GC runs. Then used BMad QA agent (Quinn) for senior developer review.

**Key technical findings from Story 1.1:**

1. **Confirmed root cause**: `/nix/var/nix/gcroots/per-user/happygopher/` does not exist
2. **Profile location issue**: Despite `useUserPackages = true`, profiles remain in XDG locations
3. **Home Manager integration**: Integrated as nix-darwin module, not standalone
4. **GC roots discovery**: Found 7 home-manager related roots in `/nix/var/nix/gcroots/auto/`
5. **Comprehensive capture**: 95 configuration files with SHA256 checksums

**BMad Dev agent issues discovered:**

- **Wrong story selection**: Picked story 1.4 when 1.1-1.3 were unimplemented
- **Ignored technical docs**: Skipped critical technical analysis link in story
- **Bad assumptions**: Tried `home-manager` command despite module integration
- **Checklist failure**: Acknowledged checklist requirement but didn't execute

**BMad QA agent (Quinn) experience:**

- Performed thorough review without issues
- Properly validated all acceptance criteria
- Only updated QA Results section as instructed
- Provided excellent technical feedback

**Outcome:** Story 1.1 completed successfully with comprehensive state capture. Updated bmad-feedback-public.md with Dev agent learnings. QA agent worked smoothly, highlighting that not all BMad agents have the same implementation issues.

**Future Me Notes:** When using BMad Dev agent, always specify exact story numbers and force it to read referenced docs. QA agent is more reliable for reviews. The technical findings confirm our suspicion about missing per-user GC roots.

---

## 007: Story 1.2 - Manual GC Test & Critical Observations

**What sparked this:** Implemented Story 1.2 to test manual GC execution, comparing behavior with automatic weekly GC.

**The journey:** Tested both `sudo nix-collect-garbage` and `nix-cleanup` alias to see if manual execution reproduces the settings loss issue.

**Key technical findings:**

1. **Manual GC does NOT break settings** - Terminal remained fully functional
2. **chmod errors protect configs** - "Operation not permitted" on iTerm2.app prevented deletion
3. **macOS permission popup** - "Cursor is prevented from changing apps"
4. **Sunday mystery** - Automatic GC should have run at 00:00 but settings intact at 06:10
5. **launchd uses `/bin/wait4path`** - Different permission context than manual execution
6. **current-home root survived** - Still protecting user profile after manual GC

**AI agent error during implementation:**

- **Command failure handling** - When `nix-store-size` (alias to `du -sh /nix/store`) timed out:
  1. Correctly found it was an alias and ran the expanded command
  2. Command timed out after 2 minutes
  3. **ERROR**: Used unrelated `df -h /nix` output showing 160GB
  4. Presented as fact: "Current Nix store usage: 160GB"
  5. User corrected: Actual was 54GB
  6. **3x error magnitude** from using wrong data source

**What we learned:**

- Manual GC behaves differently due to permission restrictions
- Automatic GC via launchd likely bypasses these restrictions
- The `/bin/wait4path` binary needs Full Disk Access (per technical docs)
- AI agents may substitute unrelated data when primary method fails
- Always verify AI-provided measurements against actual commands

**Outcome:** Story 1.2 completed, confirming manual GC cannot reproduce the issue. The permission difference between manual and automatic execution is key. Updated bmad-feedback-public.md with AI agent data fabrication issue.

**Future Me Notes:** When automatic GC breaks settings but manual doesn't, check permission contexts. For AI agents: always verify numerical outputs, especially when commands fail. The launchd environment has broader permissions than interactive shells.

---

## 008: Story 1.3 - Bug Successfully Reproduced with Two-Stage GC

**What sparked this:** Implemented Story 1.3 to test launchd-triggered GC, attempting to reproduce the actual bug scenario users experience every Sunday.

**The journey:** After initial launchd failures, discovered a specific two-stage GC sequence that successfully reproduced the P10k wizard appearance.

**Key technical findings:**

1. **Launchd chmod errors** - Initial attempts failed with "Operation not permitted" on iTerm2.app bundle (exit code 1)
2. **Two-stage GC pattern** - Bug reproduced with: `nix-cleanup` (sudo -H) followed by launchd GC
3. **Full Disk Access correlation** - Bug occurred with iTerm2 having FDA, but causation unclear
4. **Home Manager uses XDG paths** - Not traditional `/nix/var/nix/gcroots/per-user/$USER/`
5. **Both GCs run as root** - Neither directly touches user profiles, yet user config deleted

**The confusion explained:**

- **Expected (wrong)**: `/nix/var/nix/gcroots/per-user/happygopher/`
- **Actual (correct)**: `~/.local/state/home-manager/gcroots/current-home`

Home Manager follows XDG Base Directory spec. Creates indirect roots in `/nix/var/nix/gcroots/auto/` that protect generation links but not all transitive dependencies.

**Critical discovery about `sudo -H`:**

- Sets HOME to target user's home (`/var/root` for root)
- Explains why GC targets root profiles, not current user
- Both manual (`nix-cleanup`) and launchd GC run in root context

**Reproduction sequence:**

1. iTerm2 with Full Disk Access enabled
2. `nix-cleanup` → freed 10GB from system/root profiles
3. `sudo launchctl kickstart -k system/org.nixos.nix-gc` → exit code 0
4. New terminal → P10k wizard appears

**Outcome:** Bug successfully reproduced! Created comprehensive investigation report in `docs/stories/1.3-investigation-report.md` with all evidence preserved. The two-stage pattern and FDA requirement suggest complex permission interactions.

**Future Me Notes:** When debugging launchd services, check FDA status and try multi-stage operations. The 10GB freed by first GC likely included store paths that Home Manager indirectly depended on. Consider if indirect GC roots provide sufficient protection.

---

## 009: Story 1.4 Course Corrections - AI Agent Patterns & BMad Lessons

**What sparked this:** Story 1.4 required two course corrections after dev agent ran out of context mid-investigation. Revealed important patterns about AI agent behavior and BMad workflow limitations.

**The journey:** Original Story 1.4 tasks became outdated after discoveries in Stories 1.1-1.3. First correction updated tasks, then dev agent started work but Claude Code context window approached limit. Had to return to SM agent for second correction.

**Key AI agent patterns discovered:**

1. **General AI patterns** (added to ai-agents-lessons.md):
   - Stating assumptions as facts without verification
   - Narrow investigation scope (stopping at first finding)
   - Missing command documentation in reports
   - Accepting initial hypothesis despite contradictory evidence
   - Not using available resources (diving in without reading docs)
   - Incomplete investigation closure (not acknowledging unknowns)

2. **BMad-specific issues**:
   - Story purpose mismatch (keeping outdated checklist items)
   - Handoff document duplication (169 lines repeating story content)
   - No support for context limit handling mid-story

**Critical lesson about workflow:**

Should have committed incrementally:

1. First course correction
2. Dev agent work
3. Second course correction

Instead, tried to do everything at once and created confusion. Self-discipline required for baby steps.

**What we learned:**

- AI agents need explicit guidance to document evidence, not assumptions
- BMad stories can become outdated as earlier stories make discoveries
- Context window limits are real constraints requiring workflow adaptation
- Handoff documents should be navigation aids, not content duplicators
- Course correction is a valuable BMad capability that should be formalized

**Outcome:** Successfully corrected Story 1.4 to focus on completing investigation before postmortem. Updated ai-agents-lessons.md with 6 new patterns. Enhanced bmad-feedback-public.md with course correction experience.

**Future Me Notes:** When working with AI agents across long sessions, commit frequently. When course correcting, focus on WHAT needs investigation, not prescriptive HOW. BMad's SM agent can effectively update outdated stories - use this capability proactively.

---

## 010: Story 1.4 Investigation - FDA, Mount Flags, and GC Root Mysteries

**What sparked this:** After successfully reproducing the bug in Story 1.3, needed to understand WHY it happens. QA was confused about permission differences, FDA role, and deletion mechanisms.

**The journey:** Dev agent investigated 4 key questions through systematic testing and research.

**Key technical findings:**

1. **FDA enables chmod on protected paths**:
   - `/nix` mounted with "protect" flag (NOT read-only)
   - Without FDA: chmod fails with "Operation not permitted"
   - With FDA: chmod succeeds on same paths
   - No Apple documentation found explaining this behavior

2. **User configs deleted through missing transitive GC roots**:
   - Home Manager protects its generation: `~/.local/state/home-manager/gcroots/current-home`
   - But embedded store paths in configs (like `.zim/init.zsh`) have NO roots
   - Found: 49 protected symlinks, but config files with hardcoded paths vulnerable
   - Critical discovery: P10k config store path had 0 roots despite being actively used

3. **Two-stage GC pattern explained**:
   - Stage 1: Manual GC with FDA removes chmod-protected .app bundles (10GB)
   - Stage 2: launchd can complete without hitting chmod errors
   - launchd service uses `/bin/sh -c` which lacks FDA

4. **Profile protection mechanisms**:
   - System profiles: Direct GC roots, always protected
   - User nix profiles: Auto/indirect roots, protected if profile exists
   - Home Manager: Generation protected, but embedded paths NOT

**Unanswered questions remain:**

- Why does Home Manager use hardcoded paths instead of indirection?
- Can launchd services be granted FDA? (Evidence says no)
- What exactly is the "protect" mount flag? (Undocumented by Apple)

**Outcome:** Investigation incomplete but significant progress made. Now understand FDA's role, how configs get deleted, and why two-stage pattern works. Need to complete remaining investigation gaps before creating valid postmortem.

**Future Me Notes:** The bug is real and reproducible. Root cause involves missing transitive GC roots combined with FDA permission differences. When investigating system behaviors, always check mount flags, test with/without FDA, and trace GC root chains completely.

---
