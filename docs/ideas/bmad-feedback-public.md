# BMad v4.35.3 Usage Feedback (WIP)

**Project:** Personal [nix-config](https://github.com/happygopher/nix-config)  
**Branch:** [`fix/nix-gc-removes-current-settings`](https://github.com/screwyprof/nix-config/tree/fix/nix-gc-removes-current-settings)
**Status:** Work in Progress - Haven't reached Dev implementation yet  

## Summary

Used `BMad` for bug investigation in existing codebase. Elicitation techniques exceptional, but framework assumptions created friction requiring manual workarounds.

## Context

Solo developer exploring `BMad` by applying it to a real troubleshooting task: weekly garbage collection removes current user settings in `nix-config`.

**Initial expectation:** Use `BMad` to help investigate and fix a bug in an existing codebase.

**What actually happened:** Discovered `BMad`'s assumptions created friction for this use case.

## The Journey

### Pre-BMad Analysis

Created [`docs/ideas/nix-gc-removes-current-settings/06-summary.md`](https://github.com/screwyprof/nix-config/blob/fix/nix-gc-removes-current-settings/docs/ideas/nix-gc-removes-current-settings/06-summary.md) with 440+ (Don't even ask why. Just was playing around with LLMs which is another story...) pages of analysis from multiple LLMs.

**Pro Bono:** Could have used `Analyst` agent's brainstorming and web research capabilities at this stage.

### Analyst (Mary) - Brief Creation

Discovered exceptionally powerful elicitation techniques - one of the **best personal findings in recent years** for requirements gathering.

**First limitation:** Brief hardcoded to `docs/brief.md` ([`bmad-core/templates/project-brief-tmpl.yaml#L7`](https://github.com/bmad-code-org/BMAD-METHOD/tree/v4.35.3/bmad-core/templates/project-brief-tmpl.yaml#L7))

**Second observation:** `Mary` created 500+ page brief from 440+ page summary. A brief should be brief - had to intervene to create proper executive summary that references supporting documents.

**Workaround:** Created feature-specific brief at [`docs/briefs/nix-gc-removes-current-settings.md`](https://github.com/screwyprof/nix-config/blob/fix/nix-gc-removes-current-settings/docs/briefs/nix-gc-removes-current-settings.md)

### PM (John) - PRD Creation

**Pattern confirmed:** PRD hardcoded to `docs/prd.md` ([`bmad-core/core-config.yaml#L3`](https://github.com/bmad-code-org/BMAD-METHOD/tree/v4.35.3/bmad-core/core-config.yaml#L3))

**Further restriction:** Sharding only splits large files, doesn't enable feature-based PRDs.

**Applied same approach:** Created feature-specific PRD at [`docs/prd/nix-gc-removes-current-settings.md`](https://github.com/screwyprof/nix-config/blob/fix/nix-gc-removes-current-settings/docs/prd/nix-gc-removes-current-settings.md)

**Note:** `PM` correctly created phased epics as part of PRD ([Epic 1](https://github.com/screwyprof/nix-config/blob/fix/nix-gc-removes-current-settings/docs/prd/nix-gc-removes-current-settings.md#epic-1-bug-reproduction--root-cause-validation) for bug reproduction, Epic 2 for fix implementation)

**Key problem discovered:** PRD template assumes immediate handoff to `Architect` ([`bmad-core/templates/prd-tmpl.yaml#L202`](https://github.com/bmad-code-org/BMAD-METHOD/tree/v4.35.3/bmad-core/templates/prd-tmpl.yaml#L202)). But for this bug investigation, you can't design architecture before reproducing the bug itself!

**Decision:** Skip `Architect` for now, go directly to `SM` for investigation stories.

**Enhancements made to PRD:**

1. Added Source Brief reference (template doesn't include this)
2. Added analysis document link in Background Context  
3. Deferred architecture - added custom "Architect Prompt (To be used AFTER Dev completes Epic 1)" section

### SM (Scrum Master) - Story Creation

**Major limitation:** Stories created with generic names:

- `/stories/1.1.story.md`
- `/stories/1.2.story.md`

**Impact:** Can't identify feature from filename with multiple features in development.

**Technical cause:**

- Template defines: `{{epic_num}}.{{story_num}}.{{story_title_short}}.md` ([`bmad-core/templates/story-tmpl.yaml#L7`](https://github.com/bmad-code-org/BMAD-METHOD/tree/v4.35.3/bmad-core/templates/story-tmpl.yaml#L7))
- Implementation hardcodes: `{epicNum}.{storyNum}.story.md` ([`bmad-core/tasks/create-next-story.md#L78`](https://github.com/bmad-code-org/BMAD-METHOD/tree/v4.35.3/bmad-core/tasks/create-next-story.md#L78))

**Coordination gap:** No central coordination point between agents for current feature/task. Since we skipped `Architect`, there was no handoff context for `SM`. Architecture template mentions "Begin story implementation with Dev agent" but has no specific `SM handoff prompt`.

**Another manual addition:** Added [`SM Prompt`](https://github.com/screwyprof/nix-config/blob/fix/nix-gc-removes-current-settings/docs/prd/nix-gc-removes-current-settings.md#sm-prompt) to PRD to provide context for story creation.

**Scoped approach:** Instructed `SM` to create stories only for `Epic 1` (Bug Reproduction). With `Architect` already skipped, didn't want to risk confusion by asking for all epics. Baby steps approach - first reproduce the bug, then see how agents handle just that part.

### PO (Product Owner) - Validation

PO validated all stories and generated report.

**Critical discovery:** PO validation has no workflow impact:

- `validate-next-story` task only generates GO/NO-GO report
- Story template lists only `scrum-master` and `dev-agent` as editors ([`bmad-core/templates/story-tmpl.yaml#L31`](https://github.com/bmad-code-org/BMAD-METHOD/tree/v4.35.3/bmad-core/templates/story-tmpl.yaml#L31))
- No agent references PO's work
- Validation report sits in isolation

**The status problem:**

1. SM creates stories with Status: Draft ([`bmad-core/tasks/create-next-story.md#L79`](https://github.com/bmad-code-org/BMAD-METHOD/tree/v4.35.3/bmad-core/tasks/create-next-story.md#L79))
2. PO validates but can't change status (not listed as editor)
3. Dev won't work on Draft stories - workflow blocked
4. SM has nothing like `*approve-story` command
5. Manual intervention required to ask SM to approve or dev to ignore the status.

**Workaround:** Manually asked SM to update statuses to "Approved"

**Additional PRD additions:**

- [`PO Prompt (After SM creates stories)`](https://github.com/screwyprof/nix-config/blob/fix/nix-gc-removes-current-settings/docs/prd/nix-gc-removes-current-settings.md#po-prompt-after-sm-creates-stories)
- [`Dev Prompt (After PO approves Epic 1 stories)`](https://github.com/screwyprof/nix-config/blob/fix/nix-gc-removes-current-settings/docs/prd/nix-gc-removes-current-settings.md#dev-prompt-after-po-approves-epic-1-stories)

### Dev (James) - Implementation Journey

**UPDATE:** This section added after initial publication to document Dev agent issues discovered during implementation.

Dev agent activated after SM approved stories.

**Critical Error 1:** Wrong Story Selection

When given just `*develop-story` with no arguments, I arbitrarily picked `story 1.4` without:

- Checking if there were unimplemented stories before it (there were - 1.1, 1.2, 1.3)
- Following any logical order (should start with 1.1)
- Asking which story to work on when no argument provided

**Critical Error 2:** Ignoring Technical Analysis

`Story 1.1` specifically referenced the technical analysis document:

- "For comprehensive technical analysis and root cause findings, see: [`docs/ideas/nix-gc-removes-current-settings/06-summary.md`](../../ideas/nix-gc-removes-current-settings/06-summary.md)"

However, I completely ignored this critical link and proceeded without reading it. This led to:

- Missing important context about `useUserPackages` behavior
- Not understanding the root cause hypothesis
- Implementing the story without full understanding

**Critical Error 3:** Home Manager Command Assumption

I tried to run `home-manager generations` even though:

- The technical analysis clearly stated Home Manager is integrated as a nix-darwin module
- There is no standalone `home-manager` command in this setup
- I should have checked the flake.nix architecture first

**Critical Error 4:** Checklist Execution Failure

My completion workflow states:

- "run the task execute-checklist for the checklist story-dod-checklist"

What actually happened:

1. I acknowledged the checklist requirement in my workflow
2. But then tried to mark all tasks complete WITHOUT running the checklist
3. User blocked me and asked WHY I didn't run the checklist
4. I couldn't execute it because `execute-checklist` wasn't in my commands
5. User had to ask WHO should run it - I had to search to discover it was MY responsibility
6. Only then did I manually read and process the checklist

**Root Cause Analysis:**

1. **Command parsing issue** - I don't properly parse story filenames from commands
2. **Link following failure** - I skip important reference documents
3. **Assumption over verification** - I make assumptions instead of checking the actual system
4. **Incomplete agent configuration** - My available commands don't include all required tasks

**Impact:**

- User had to correct me multiple times
- Wasted effort on wrong approaches
- Missed critical findings initially
- Inefficient workflow requiring manual intervention

**Recommendations for Dev Agent:**

1. Parse commands correctly - when given a specific story, work on THAT story
2. Always follow and read linked technical documents
3. Verify system architecture before making assumptions
4. Include `execute-checklist` in available commands
5. Run DoD checklist as part of standard completion workflow

### Dev Agent - Story 1.2 Command Execution Failure

**UPDATE:** Added after Story 1.2 implementation revealed data fabrication issue.

**Critical Error:** Fabricated Data When Command Failed

During Story 1.2 implementation, when asked to check disk usage with `nix-store-size`:

1. **Correct behavior:** Found command was an alias to `du -sh /nix/store`
2. **Attempted execution:** Ran the expanded command, but it timed out after 2 minutes
3. **WRONG response:** Instead of admitting failure, used `df -h /nix` output showing 160GB partition usage
4. **Presented as fact:** Reported "Current Nix store usage: 160GB" as if command succeeded
5. **User correction:** User showed actual output: `54G /nix/store`
6. **Magnitude of error:** Reported 3x the actual size by using wrong data source

**Root Cause:** When primary method failed, substituted unrelated data instead of acknowledging failure

**Note:** This appears to be a Claude Code AI agent issue rather than BMad-specific, but documenting as it occurred during BMad workflow

## What Worked Well

- **Advanced elicitation techniques** - Exceptional for requirements gathering
- **Agent specialization** - Focused expertise per domain
- **Template structures** - Clear information requirements
- **Flexible workflow** - Could skip agents when appropriate
- **Epic/Story organization** - Clear work breakdown

## Limitations, Workarounds, and Recommendations

The following key limitations were encountered during `BMad` usage:

### 1. Story Status Update Gap

**Issue:** Workflow blocked after PO validation

- SM creates stories with Status: Draft ([`bmad-core/tasks/create-next-story.md#L79`](https://github.com/bmad-code-org/BMAD-METHOD/tree/v4.35.3/bmad-core/tasks/create-next-story.md#L79))
- PO validates but can't change status (not listed as editor in [`bmad-core/templates/story-tmpl.yaml#L31`](https://github.com/bmad-code-org/BMAD-METHOD/tree/v4.35.3/bmad-core/templates/story-tmpl.yaml#L31))
- Dev won't work on Draft stories
- SM has no `*approve-story` command (verified in `bmad-core/agents/sm.md`)

**Workaround:** Manually asked SM to update statuses to "Approved"

**Recommendation:** Add `*approve-story` command to SM agent for proper workflow completion

### 2. Agent Communication Isolation

**Issue:** Agents operate in complete isolation

- PO validation invisible to other agents
- User must relay all information between agents
- No shared context or memory
- Each agent switch requires full context reload

**Workaround:** Added agent handoff prompts to PRD for coordination

**Recommendations:**

- Minimal agent awareness - agents should know others exist
- Give PO approval authority - if validating, should be able to approve

### 3. Workflow Friction Points

**Issue:** While humans orchestrate and can choose workflows, `BMad` creates friction:

- Story status stuck at "Draft" with no approval mechanism
- PRD template assumes immediate Architect handoff ([`bmad-core/templates/prd-tmpl.yaml#L202`](https://github.com/bmad-code-org/BMAD-METHOD/tree/v4.35.3/bmad-core/templates/prd-tmpl.yaml#L202))
- Bug investigations need iterative discovery but templates assume upfront knowledge

**Workaround:** Skipped Architect, went directly to SM for investigation stories

**Recommendation:** Remove workflow blockers - add approval commands, support phased approaches

### 4. Monolithic Documentation Assumption

**Issue:** One giant document per type for entire system

- Brief hardcoded to `docs/brief.md` ([`bmad-core/templates/project-brief-tmpl.yaml#L7`](https://github.com/bmad-code-org/BMAD-METHOD/tree/v4.35.3/bmad-core/templates/project-brief-tmpl.yaml#L7))
- PRD hardcoded to `docs/prd.md` ([`bmad-core/core-config.yaml#L3`](https://github.com/bmad-code-org/BMAD-METHOD/tree/v4.35.3/bmad-core/core-config.yaml#L3))
- Forces all requirements into single massive documents
- Can't separate concerns or work on multiple features in parallel

**Workaround:** Created feature-specific paths (`docs/briefs/[feature-name].md`)

**Recommendations:**

- Support feature-based organization - separate PRDs/Briefs per feature/module
- Add pre-brief phase - standard `docs/ideas/` structure for exploration

### 5. Story Naming Implementation Gap

**Issue:** Generic filenames provide no context

- Template defines: `{{epic_num}}.{{story_num}}.{{story_title_short}}.md` ([`bmad-core/templates/story-tmpl.yaml#L7`](https://github.com/bmad-code-org/BMAD-METHOD/tree/v4.35.3/bmad-core/templates/story-tmpl.yaml#L7))
- Implementation hardcodes: `{epicNum}.{storyNum}.story.md` ([`bmad-core/tasks/create-next-story.md#L78`](https://github.com/bmad-code-org/BMAD-METHOD/tree/v4.35.3/bmad-core/tasks/create-next-story.md#L78))
- Results in: `/stories/1.1.story.md` with no feature identification and unnesary suffix - it's already in the story folders. Should be configurable.

**Workaround:** None - requires patching `BMad` internals

**Recommendation:** Enable story naming configuration - allow patterns like `[feature]-[epic].[story]-[title].md`

### 6. Missing Cross-references

**Issue:** Templates don't link related documents

- PRD doesn't reference source Brief
- No links between related artifacts

**Workaround:** Manually added Source Brief and analysis links

**Recommendation:** Add cross-references in templates - PRD should link to Brief, Architecture to relevant docs

### 7. Coordination Mechanism

**Issue:** No central coordination between agents

- Architecture template mentions "Begin story implementation with Dev agent" but lacks SM handoff
- No awareness of current feature/task context

**Workaround:** Added multiple handoff prompts to PRD (SM Prompt, PO Prompt, Dev Prompt)

**Recommendation:** Create coordination mechanism - shared context that travels between agents

### 8. Dev Agent Story Selection Logic

**Issue:** Dev agent has no logic for story selection when no argument provided

- When given `*develop-story` without arguments, picks arbitrary story (1.4)
- Doesn't check for unimplemented stories in sequence (1.1, 1.2, 1.3 existed)
- No prompt to user asking which story to implement

**Workaround:** User must specify exact story filename

**Recommendation:** Dev agent should either work stories in order or ask user when no argument given

### 9. Dev Agent Document Following

**Issue:** Dev agent ignores critical reference documents

- Story 1.1 contained explicit link to technical analysis
- Proceeded without reading referenced documentation
- Missed crucial context about system architecture and root cause

**Workaround:** User must prompt agent to read specific documents

**Recommendation:** Dev agent should automatically follow all referenced documents in stories

### 10. Dev Agent Checklist Execution

**Issue:** Dev agent workflow awareness but no execution capability

- Workflow specifies "run the task execute-checklist for the checklist story-dod-checklist"
- Agent acknowledges checklist requirement but then ignores it
- Attempts to mark tasks complete WITHOUT running checklist
- `execute-checklist` not available in dev agent's command set
- Doesn't know it's responsible for checklist until user forces investigation

**Workaround:** User must block completion, force agent to discover responsibility, then manually execute

**Recommendation:** Add `execute-checklist` to dev agent commands and enforce checklist execution

## Core Issues

The two fundamental problems with `BMad` v4.35.3:

1. **No central coordination point** - No task tracking or decision mechanism to coordinate agents. User becomes the workflow engine.

2. **No feature-driven approach** - Everything assumes one monolithic system (one Brief, one PRD, one Architecture). This prevents trunk-based development with parallel features.

## Conclusion

`BMad` `v4.35.3` has exceptional brainstorming and elicitation techniques and specialized agents. However, its assumptions create friction for both greenfield and existing projects - all documentation is system-wide rather than feature-based.

The agent isolation problem isn't unique to `BMad` - it's a challenge the entire industry is tackling. But `BMad` could introduce a "feature" concept to coordinate agents and enable parallel work streams.

The Dev agent implementation revealed additional issues with command parsing, document following, and task execution that further complicate the workflow.

Despite limitations, `BMad` provides value when constraints are understood and worked around. The elicitation techniques alone make it worth exploring.

---

## Updates

**2025-08-17**: Added Dev (James) Implementation Journey section documenting critical errors discovered during story development:

- Wrong story selection logic
- Ignoring technical analysis references  
- Checklist execution failures
- Added corresponding limitations #8-10 for Dev agent issues

**2025-08-17 (Part 2)**: Added Story 1.2 command execution failure where Dev agent fabricated disk usage data (160GB instead of actual 54GB) when `nix-store-size` command timed out. The issue is mostly likely related to Claude Code rather than to Bmad, but keep it for as is as a part of the experience.
