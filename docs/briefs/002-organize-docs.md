# Documentation Organization System Brief

## Overview

A flexible documentation structure that preserves BMad compatibility while allowing pragmatic shortcuts for simpler changes in a personal nix-config project.

## Problem

BMad-Method provides excellent structure for complex projects, but applying its full SDLC flow to every nix-config change creates unnecessary overhead. We need:

- Ability to skip BMad stages when they don't add value
- Clear tracking of feature evolution from idea to implementation
- Compatibility with BMad agents when we do need them
- Visibility into which BMad stages were actually used

## Solution

Create a hybrid structure that maintains BMad's expected directories while adding a `features/` folder for evolution tracking. Each feature gets a flat markdown file showing its journey through (or around) the BMad flow.

### Core Structure

```
docs/
├── briefs/                # All feature briefs
│   ├── 002-organize-docs.md
│   └── 003-decision-journal.md
├── features/              # Feature evolution tracking (flat files)
│   ├── 001-bmad-integration.md
│   ├── 002-organize-docs.md
│   └── 003-decision-journal.md
├── prd/                   # BMad PRDs (when needed)
│   └── {NNN}-{name}/      # Sharded PRD files
├── architecture/          # BMad architecture (when needed)
│   └── {NNN}-{name}/      # Sharded architecture files
├── stories/               # BMad stories (when needed)
│   └── {NNN}-{name}-{num}.md
├── brief.md               # System overview (BMad default)
└── DECISIONS.md           # Decision journal
```

### Key Innovation: Evolution Tracking

Each feature file in `features/` tracks its path through the SDLC with a checklist:

```markdown
### Evolution Checklist
- [ ] Brief created
- [ ] PRD needed? → No (internal tooling)
- [ ] Architecture needed? → Yes (system design)
- [ ] Stories needed? → No (single-person work)
- [ ] Implementation complete
- [ ] Logged in DECISIONS
```

## Implementation Approach

1. Create folder structure
2. Document feature 002 (this system) as first example
3. Update existing features (001, 003) to follow pattern
4. Create architecture document for the system

## Success Criteria

- Can use full BMad flow when beneficial
- Can skip to implementation for simple changes
- Clear visibility into feature evolution
- BMad agents work with custom paths
- Decision rationale captured in DECISIONS.md

## The Skip Decision Framework

For each feature, ask:
- **Need Brief?** → Only if you need to think through the problem
- **Need PRD?** → Almost never (nix-config has no "users")
- **Need Architecture?** → Only for complex technical decisions  
- **Need Stories?** → Only for complex multi-step implementation
- **Need Decision Entry?** → Always (captures the journey)

What EVERY feature needs in `features/`:
- **Status**: Planning/In Progress/Complete
- **Evolution Checklist**: What BMad stages you used/skipped
- **Evolution Path**: The journey from idea to implementation
- **Summary**: What this feature is (essential if no brief exists)
- **What Changed**: Actual implementation details
- **Related Docs**: Links to brief, PRD, etc. (if they exist)

Brief vs Feature:
- **Brief**: Planning document (problem, solution, approach)
- **Feature**: Execution tracker (status, journey, what was built)
- Don't duplicate - if brief exists, link to it
- If no brief, feature must explain what it's about
- Decisions link back to features when applicable

## Implementation

This system has been implemented during this session. We're using it for features 001, 002, and 003.