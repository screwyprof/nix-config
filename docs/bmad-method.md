# BMad Method v4 - Practical Workflow Guide

Your complete guide for AI-powered development using BMad agents.

## Quick Decision Guide

```
What are you building?
├─ Bug fix or tiny change → Simple Workflow
├─ New feature (small) → Standard Workflow  
├─ Complex feature → Full Workflow
└─ Just exploring → Start with Analyst
```

## Core Workflows

### 🔧 Simple Workflow - Bug Fixes & Small Changes

```bash
# One story, straight to implementation
@pm *create-brownfield-story              # Create single story
@dev *develop-story {story-name}          # NEW CHAT! Implement it
```

**When to use**: Bug fixes, config changes, small UI tweaks, single-file changes

### 📦 Standard Workflow - Regular Features

```bash
# 1. Requirements
@pm *create-brownfield-prd                # Define requirements
→ Creates: docs/prd.md

# 2. Story Creation - NEW CHAT!
@sm *draft                                # Create dev-ready stories
→ Creates: docs/stories/*.md

# 3. Implementation - NEW CHAT per story!
@dev *develop-story {story-name}          # Build each story
@qa *review {story-name}                  # Optional review
```

**When to use**: Features that need planning but follow existing patterns

### 🚀 Full Workflow - Complex Features

```bash
# 1. Research & Ideation
@analyst *brainstorm "feature idea"       # Explore possibilities
@analyst *research-prompt "topic"         # Deep research
@analyst *elicit                          # Detailed requirements

# 2. Requirements & Planning
@pm *create-prd                           # Comprehensive PRD
→ Creates: docs/prd.md

# 3. Technical Design
@architect *create-full-stack-architecture # System design
→ Creates: docs/architecture.md

# 4. Validation & Organization
@po *execute-checklist-po                 # Ensure alignment
@po *shard-doc docs/prd.md docs/prd      # If multi-epic

# 5. Story Creation - NEW CHAT!
@sm *draft                                # Implementation stories
→ Creates: docs/stories/*.md

# 6. Build & Review - NEW CHAT per story!
@dev *develop-story {story-1.1}           # Implement
@qa *review {story-1.1}                   # Code review
```

**When to use**: New systems, major refactors, multi-sprint features

## Critical Rules

1. **ALWAYS start new chat** between SM → Dev → QA
2. **One story per dev session** - Don't batch stories
3. **Stories live in** `docs/stories/` always
4. **Skip agents when not needed** - Not every change needs all agents

## Story Creation Guide

```
Need a story?
├─ Quick fix? → PM (*create-brownfield-story)
├─ Have PRD? → SM (*draft)  
└─ Need validation? → PO (*validate-story-draft)
```

**PM Stories**: Business-focused, single features, no PRD needed  
**SM Stories**: Technical implementation from PRD/Architecture  
**PO Role**: Validates and refines existing stories

## Document Organization

**Standard Structure**
- Brief: `docs/briefs/` - Problem & vision (optional)
- PRD: `docs/prd.md` - Requirements
- Architecture: `docs/architecture.md` - Technical design
- Stories: `docs/stories/` - Implementation tasks

**For Large Projects (Sharding)**
- PRD: `docs/prd/epic-*.md`
- Architecture: `docs/architecture/*.md`
- Config: Set `prdSharded: true`

## Tips & Best Practices

1. **Start simple** - Use PM for quick stories, skip unnecessary agents
2. **Context matters** - New chat = clean context = better results
3. **Let agents focus** - Each has specific expertise
4. **Skip when obvious** - No architect needed if following patterns
5. **Brief is optional** - Only for exploring new problem spaces

## When to Skip Agents

**Skip Analyst when**
- Requirements are clear
- Not exploring new territory
- Simple bug fix or addition

**Skip Architect when**
- Following existing patterns
- No new technical decisions
- Simple CRUD operations

**Skip PO when**
- Single story implementation
- Clear requirements
- Time-sensitive fixes

**Skip QA when**
- Trivial changes
- Config updates
- Following tested patterns

---

## Agent Reference

### 🔍 Analyst - Research & Ideation
**Purpose**: Explore problems, research solutions, document findings

```
*brainstorm {topic}       # Generate ideas
*research-prompt {topic}  # Deep research
*document-project         # Analyze existing code
*elicit                   # Detailed requirements gathering
```

### 📋 PM - Product Manager
**Purpose**: Create requirements, PRDs, and business-oriented stories

```
*create-prd                    # Full PRD from scratch
*create-brownfield-prd         # PRD for existing system
*create-brownfield-epic        # Epic with 2-3 stories
*create-brownfield-story       # Single story (no PRD)
*shard-prd                     # Split large PRD
```

### 🏗️ Architect - Technical Design
**Purpose**: Design systems, create technical documentation

```
*create-backend-architecture       # API/service design
*create-full-stack-architecture    # Complete system
*create-front-end-architecture     # UI architecture
*create-brownfield-architecture    # For existing systems
*shard-prd                         # Actually shards architecture!
*research {topic}                  # Technical research
```

### ✅ PO - Product Owner
**Purpose**: Validate quality, refine stories, ensure alignment

```
*execute-checklist-po          # Quality validation
*validate-story-draft {story}  # Review story quality
*shard-doc {doc} {dest}        # Organize documents
*create-epic                   # Create epic structure
*create-story                  # Refine stories
*correct-course                # Fix misalignment
```

### 📝 SM - Scrum Master
**Purpose**: Transform PRDs into developer-ready implementation stories

```
*draft               # Create implementation stories from PRD
*correct-course      # Adjust approach
*story-checklist     # Validate story completeness
```

### 💻 Dev - Developer
**Purpose**: Implement stories with code

```
*develop-story {story}  # Build the feature
*run-tests              # Execute test suite
*explain                # Explain implementation
```

### 🔎 QA - Quality Assurance
**Purpose**: Review code quality and implementation

```
*review {story}  # Comprehensive code review
```

### 🧙 BMad Master - Universal Agent
**Purpose**: Administrative tasks, NOT for implementation

```
*shard-doc {src} {dest}        # Split documents
*task {any-task}               # Run any BMad task
*create-doc {template}         # Create from template
*execute-checklist {name}      # Run checklists
*kb                            # Knowledge base
```

**WARNING**: Never use BMad Master for SM/Dev/QA work!

---

Remember: BMad amplifies capability when complexity demands it. Start simple, add agents as needed.