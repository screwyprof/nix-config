# Decision Journal Feature Brief

## Overview

A system to capture the "why" behind configuration changes in a human-friendly, searchable format that helps future understanding of past decisions.

## Problem

Currently, git commits capture what changed but lack context on:
- Why the change was needed
- What alternatives were tried
- What problems it solved
- What to check if it breaks

Six months later, it's hard to understand why specific implementation choices were made, especially after trying multiple approaches that didn't work.

## Solution

A single `DECISIONS.md` file with chronological entries that tell the story of each significant change using a consistent, conversational format.

### Key Features

1. **Structured Story Format**
   - Human-friendly narrative style
   - Consistent sections for easy scanning
   - Searchable by content (tool names, problems)

2. **AI-Assisted Capture**
   - Automatic detection of decision moments ("That fixed it!", "This works now")
   - AI maintains draft throughout conversation in background
   - Natural prompts for missing information ("What should future you know?")
   - `/capture-decision` as manual fallback when automatic capture fails

3. **Git Integration**
   - Each decision has sequential ID (#001, #002, etc.)
   - Commit messages reference: `fix(colima): resolve memory allocation (#001)`
   - Optional: Auto-generate commit messages from decisions

## Format Template

```markdown
## {sequential-number}: {Brief problem description}

**Feature**: {Link to feature tracker if applicable}

**What sparked this:** {The trigger/frustration that started this work}

**The journey:** {Natural language story of what you tried}

**What we tried:**
1. {First attempt} → {Result}
2. {Second attempt} → {Result}
3. {Final solution} → {Success}

**Outcome:** {What changed and how it's better}

**Future Me Notes:** {Direct advice to yourself when you hit this again}
```

## Language Guidelines

### Do:
- Write conversationally: "Got tired of X, so tried Y"
- Use specific examples: "2GB instead of 16GB"
- Include actual commands: `colima status`
- Be honest about frustrations and time spent
- Address future self directly

### Don't:
- Use corporate speak or jargon
- Write in passive voice
- Add marketing fluff or superlatives
- Include unnecessary technical ceremony

## Workflow

1. Start work on a problem
2. AI automatically detects decision context and maintains draft
3. AI prompts naturally: "What should future you know about this?"
4. Before commit, review/edit the decision entry
5. Commit with reference: `fix(colima): resolve memory allocation (#001)`
6. Use `/capture-decision` only if automatic capture missed something

## Success Criteria

- Easy to write during work (not after)
- Valuable when read months later
- Searchable by content
- No friction in development workflow
- Natural language that sounds like the user wrote it

## Open Questions

1. Should we auto-generate commit messages from decision entries?
2. How to handle decisions that span multiple work sessions?
3. Should experimental changes be marked differently?

## Next Steps

1. Create PRD with detailed requirements
2. Design technical implementation (AI commands, templates, automation)
3. Build prototype with next real configuration change
4. Iterate based on usage