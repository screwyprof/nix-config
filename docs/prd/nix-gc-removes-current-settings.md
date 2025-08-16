# Nix GC Fix Product Requirements Document (PRD)

**Source Brief:** [`docs/briefs/nix-gc-removes-current-settings.md`](../briefs/nix-gc-removes-current-settings.md)

## Goals and Background Context

### Goals

- Terminal configurations survive weekly automatic garbage collection
- GC roots are properly registered in `/nix/var/nix/gcroots/per-user/$USER/`
- Both manual and automatic GC clean effectively without breaking user configurations
- User generations are maintained at a reasonable number (≤3 for both system and HM)
- Fix operates within macOS security constraints (SIP enabled)

### Background Context

Weekly automatic garbage collection on macOS systems using `nix-darwin` with `Home Manager` is deleting active terminal configurations, forcing users to rebuild their systems every Sunday. Root cause analysis revealed missing `GC root` directories, stale GC roots in auto directories, and permission differences between manual terminal `GC` and launchd-triggered automatic GC. This issue affects developers who rely on consistent terminal environments and wastes time with repeated system rebuilds.

**For comprehensive technical analysis and detailed findings, see:** [`docs/ideas/nix-gc-removes-current-settings/06-summary.md`](../ideas/nix-gc-removes-current-settings/06-summary.md)

## Requirements

### Functional

- **FR1:** System shall ensure Home Manager profile GC roots are created in `/nix/var/nix/gcroots/per-user/$USER/` during activation
- **FR2:** System shall clean stale GC roots from `/nix/var/nix/gcroots/auto/` that point to non-existent paths
- **FR3:** Garbage collection shall preserve currently active system and user configurations
- **FR4:** Both manual (`nix-cleanup` alias) and automatic (launchd) GC shall function identically
- **FR5:** System shall maintain specified number of generations (≤3) for both system-wide and user-level profiles
- **FR6:** GC shall handle both `useUserPackages = true` and XDG-based Home Manager configurations

### Non Functional

- **NFR1:** Solution must work within macOS SIP constraints without requiring SIP disablement
- **NFR2:** Fix must not require manual intervention after initial implementation
- **NFR3:** Performance impact on weekly GC runs shall be negligible (<5% increase in execution time)
- **NFR4:** Solution shall be compatible with existing nix-darwin and Home Manager configurations
- **NFR5:** Implementation shall preserve backward compatibility with current user workflows
- **NFR6:** Fix shall include appropriate logging for troubleshooting GC operations

## Technical Assumptions

### Repository Structure: Monorepo

This fix will be implemented within the existing nix-config monorepo structure.

### Service Architecture

Not applicable - this is a configuration fix for an existing nix-darwin/Home Manager setup, not a service architecture change.

### Testing Requirements

- Manual testing of both root-initiated and launchd-triggered GC
- Verification scripts to confirm GC root creation and cleanup
- Test scenarios for both fresh installs and migrations
- Regression testing to ensure existing workflows remain functional

### Additional Technical Assumptions and Requests

- Fix will leverage existing nix-darwin and Home Manager activation hooks
- Solution must be compatible with both `useUserPackages = true` and XDG-based configurations
- Implementation will follow Nix best practices for garbage collection root management
- Changes will be minimal and focused on the specific GC root issue
- macOS permission constraints (SIP, launchd) must be respected throughout

## Epic List

- **Epic 1: Bug Reproduction & Root Cause Validation**: Systematically reproduce the bug and validate root cause analysis findings
- **Epic 2: Core GC Fix Implementation**: Implement the fix for GC root registration and cleanup
- **Epic 3: Testing & Validation**: Comprehensive testing to ensure the fix works in all scenarios

## Epic 1: Bug Reproduction & Root Cause Validation

Systematically reproduce the weekly GC bug and validate the root cause analysis findings to ensure we're fixing the right problem.

### Story 1.1: Capture Current Working State

As a developer,
I want to capture the current working terminal configuration state,
so that I can compare before and after GC states.

#### Acceptance Criteria

1: Capture all relevant configuration files from ~/.config/zsh, ~/.cache, and XDG directories
2: Document current GC root structure in /nix/var/nix/gcroots/
3: Record current generation numbers for both system and user profiles
4: Store captured state in ./temp/ directory for comparison
5: Create checksums of critical configuration files

### Story 1.2: Test Manual GC as Root

As a developer,
I want to test garbage collection when run manually as root,
so that I can verify if the issue is specific to launchd execution.

#### Acceptance Criteria

1: Execute GC using sudo with the same parameters as the weekly job
2: Verify if terminal configurations remain intact after GC
3: Document any differences in GC root handling between manual and automatic runs
4: Check if P10k wizard is triggered after manual GC
5: Compare post-GC state with captured baseline

### Story 1.3: Test Launchd-Triggered GC

As a developer,
I want to test garbage collection when triggered by launchd,
so that I can reproduce the actual bug scenario.

#### Acceptance Criteria

1: Force launchd service to run (simulate Sunday 00:00 trigger)
2: Verify that terminal configurations are deleted (P10k wizard appears)
3: Document permission differences between manual and launchd execution
4: Capture error logs or permission denials from launchd context
5: Confirm missing /nix/var/nix/gcroots/per-user/$USER/ directory

### Story 1.4: Create Bug Reproduction Report

As a developer,
I want to document the reproduction findings,
so that we have a clear baseline for validating the fix.

#### Acceptance Criteria

1: Create detailed postmortem based on reproduction results
2: Compare findings with existing root cause analysis in 06-summary.md
3: Document any new discoveries or deviations from expected behavior
4: Include screenshots or logs of P10k wizard activation
5: Provide clear reproduction steps for QA validation

## Epic 2: Core GC Fix Implementation

Implement the necessary changes to ensure GC roots are properly created and maintained for Home Manager profiles.

### Story 2.1: Fix GC Root Directory Creation

As a developer,
I want to ensure the per-user GC root directory is created,
so that Home Manager can register its GC roots properly.

#### Acceptance Criteria

1: Implement directory creation in appropriate activation hook
2: Ensure directory has correct permissions for user access
3: Handle both fresh installs and existing systems
4: Directory persists across system rebuilds
5: Solution works within SIP constraints

### Story 2.2: Clean Stale GC Roots

As a developer,
I want to clean up stale GC roots in auto directories,
so that GC doesn't fail on non-existent paths.

#### Acceptance Criteria

1: Implement stale root detection logic
2: Safely remove roots pointing to non-existent paths
3: Preserve valid auto-generated roots
4: Add logging for cleaned roots
5: Handle edge cases (symlink loops, permission errors)

### Story 2.3: Update nix-cleanup Alias

As a developer,
I want to fix the nix-cleanup alias to handle all profile types,
so that manual GC works consistently.

#### Acceptance Criteria

1: Update alias to handle both system and user profiles
2: Implement proper generation limiting (≤3)
3: Ensure compatibility with both old and new HM configurations
4: Add verbose output option for troubleshooting
5: Test with various profile locations

### Story 2.4: Handle Launchd Permission Issues

As a developer,
I want to ensure the fix works with launchd's permission context,
so that automatic GC functions correctly.

#### Acceptance Criteria

1: Implement solution that works within launchd's restricted context
2: Avoid operations requiring elevated permissions
3: Add appropriate error handling for permission denials
4: Ensure logging works from launchd context
5: Test with actual launchd service (not just sudo)

## Epic 3: Testing & Validation

Comprehensive testing to ensure the fix resolves the issue without breaking existing functionality.

### Story 3.1: Create Automated Test Suite

As a developer,
I want to create automated tests for GC operations,
so that we can prevent regression.

#### Acceptance Criteria

1: Create test script for GC root creation verification
2: Implement tests for both manual and automatic GC
3: Add tests for edge cases (missing directories, permissions)
4: Include performance benchmarks
5: Tests can run in CI environment

### Story 3.2: Perform Integration Testing

As a QA engineer,
I want to test the fix in a complete system context,
so that I can verify it works with real configurations.

#### Acceptance Criteria

1: Test on fresh nix-darwin installation
2: Test on system with existing generations and configurations
3: Verify fix works with both useUserPackages configurations
4: Confirm weekly GC doesn't trigger P10k wizard
5: Validate generation limiting works correctly

### Story 3.3: Create User Documentation

As a developer,
I want to document the fix and any migration steps,
so that users can apply it successfully.

#### Acceptance Criteria

1: Document any manual steps required after applying fix
2: Explain how to verify fix is working
3: Provide troubleshooting guide for common issues
4: Include rollback instructions if needed
5: Update relevant comments in configuration files

## Checklist Results Report

### PM Validation Summary

- **Overall Completeness**: 85% (Appropriate for bug fix scope)
- **Readiness**: READY FOR SM TO CREATE STORIES (Skipping Architect Phase 1)
- **Blockers**: None
- **Key Strengths**: Clear problem definition, well-structured epics, appropriate scope
- **Note**: This is a simple configuration bug - reproduction requires no architectural design

All categories PASS or N/A for bug fix context. PRD validated and ready for story creation by SM.

## Next Steps

### UX Expert Prompt

Not applicable - this is a system-level bug fix with no user interface components.

### SM Prompt

"Create development stories for Epic 1 (Bug Reproduction) using *draft command. The PRD is at `./prd/nix-gc-removes-current-settings.md`. No architectural design needed for reproduction - this is a straightforward configuration bug. Focus on creating detailed, self-contained stories with clear reproduction steps from the PRD epic details."

### PO Prompt (After SM creates stories)

"Execute `*execute-checklist-po` to assess overall documentation health for the Nix GC bug fix project (brief: `docs/briefs/nix-gc-removes-current-settings.md`, PRD: `docs/prd/nix-gc-removes-current-settings.md`, stories: `docs/stories/1.*.story.md`).

After checklist completion, validate each Epic 1 draft story (1.1 through 1.4) using `*validate-story-draft` command. Focus on:

1. Self-containment - Dev should not need to reference PRD/Architecture for Epic 1 reproduction
2. Clear reproduction steps with expected outcomes
3. Proper file paths and technical context
4. Actionable tasks with verification criteria

Note: This is a bug reproduction epic - no architectural design was used per the PRD's guidance to skip Architect for Phase 1.

Once all stories pass validation, approve them for Dev implementation."

### Dev Prompt (After PO approves Epic 1 stories)

```markdown
# Epic 1 Implementation: Nix GC Bug Reproduction

Implement Epic 1 stories (1.1 through 1.4) for the Nix GC bug reproduction. The approved stories are at `docs/stories/1.*.story.md`.

## Pre-Implementation Steps

1. Load technical analysis at `docs/ideas/nix-gc-removes-current-settings/06-summary.md`

## Implementation Instructions

Execute `*develop-story` for each story file sequentially (1.1 → 1.2 → 1.3 → 1.4)

## Key Context

- This is a bug reproduction epic - focus on systematic investigation
- Work in the existing nix-config repository following established patterns
- Create all output in `temp/` directory structure as specified in stories
- Use existing Nix commands from CLAUDE.md where applicable

## Testing Requirements

- Start with isolated testing (`nix shell`) when possible
- If GC behavior differs in isolation, test on real system
- Bug manifests differently between manual and launchd GC - both must be tested
- If terminal configs are deleted during testing, use `nix-rebuild-host` to restore

## Critical: Sudo Command Handling

Claude Code cannot handle sudo password prompts. When you need sudo:

1. Present the command in a code block
2. Say exactly: "Please run this command manually and paste the output:"
3. Wait for user response
4. Continue with analysis based on provided output

## Final Deliverable

- Complete bug reproduction across all 4 stories
- Comprehensive postmortem report at `docs/postmortems/nix-gc-removes-current-settings.md` (Story 1.4)
- All story files updated with completion status and dev records

## Begin

Start by loading context files, then execute `*develop-story` for story 1.1.
```

### Architect Prompt (To be used AFTER Dev completes Epic 1)

"Create architecture document for the Nix GC bug fix using *create-backend-architecture. Review:

- PRD in `./prd/nix-gc-removes-current-settings.md`
- Technical analysis in `docs/ideas/nix-gc-removes-current-settings/06-summary.md`
- Dev's reproduction findings (ask user: 'What were the findings from Epic 1 reproduction?')

**CONTEXT**: You are being engaged after Epic 1 (Bug Reproduction) has been completed by Dev. The reproduction was done without architectural guidance since it's a straightforward configuration bug. Your focus is solely on designing the fix (Epic 2) based on the confirmed findings. Select the appropriate solution from the technical analysis options that best addresses the confirmed root cause."
