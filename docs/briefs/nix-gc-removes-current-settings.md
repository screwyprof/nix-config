# Project Brief: Nix GC Bug Fix

## Executive Summary

Weekly automatic garbage collection on macOS deletes user terminal configurations, requiring full system rebuilds every Sunday. Root cause analysis completed in [06-summary.md](../ideas/nix-gc-removes-current-settings/06-summary.md).

## Problem Statement

Automatic GC (Sundays at midnight) deletes active shell configurations. Investigation found:

- Missing `/nix/var/nix/gcroots/per-user/$USER/` directory
- Stale GC root in `/nix/var/nix/gcroots/auto/`
- 100+ accumulated user generations
- Manual vs automatic GC behave differently (launchd permissions)

## Target Users

Developers using nix-darwin with Home Manager

## Success Metrics

1. **Terminal survives GC**: After fix, running Sunday GC doesn't trigger P10k wizard
2. **GC roots registered**: `/nix/var/nix/gcroots/per-user/$USER/` exists with valid links
3. **Cleanup effective**: User generations reduced from 100+ to <10
4. **Both GC types work**: Manual AND automatic GC clean properly without breaking configs

## MVP Scope

**Phase 1 - Reproduction (as user specified):**

1. Capture working state: configs in ~/.config/zsh, ~/.cache, XDG dirs (in `./temp/`)
2. Test GC as root - does it break user terminal?
3. If not broken, force launchd service (simulate Sunday 00:00)
4. Document findings and create postmortem based on the summary and the factual data you get.

**Phase 2 - Implementation ([solutions in summary](../ideas/nix-gc-removes-current-settings/06-summary.md#5-comprehensive-solutions--recommendations)):**

1. Fix missing GC root (multiple methods available)
2. Fix nix-cleanup alias to handle both user and system profiles
3. Address macOS permission issues (several approaches possible)
4. Consider architectural improvements (see Future Considerations in summary)

## Constraints

- macOS SIP/chmod issues documented in summary
- `useUserPackages = true` but profiles in XDG location (user migrated from one approch to another, check orignal fix attemp in mentiond in the summary with the corresponding git commit)
- Launchd has different permissions than terminal

## PM Handoff

### PM Prompt

"Create a PRD based on this brief at `docs/briefs/nix-gc-removes-current-settings.md`.

Key inputs:

- This brief documenting a weekly GC bug
- Technical analysis: `docs/ideas/nix-gc-removes-current-settings/06-summary.md`
- BMad guidance: `docs/ideas/bmad/lessons-learned.md`

Determine:

- Whether to use greenfield or brownfield PRD template
- How to structure the workflow (phases, epics)
- Which agents are needed for each phase
- Any workflow deviations from standard BMad

Place the PRD in `docs/prd/` directory."
