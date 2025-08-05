# BMad-Method Cheatsheet

Quick reference for using BMad Method with Claude Code for AI-driven development.

## When to Use BMad

**✅ Use BMad for:**
- Multi-part features requiring planning
- Major refactoring across multiple files
- Complex debugging needing systematic approach
- Architecture decisions and documentation
- Creating comprehensive project documentation

**❌ Skip BMad for:**
- Single-file changes
- Simple bug fixes
- Minor config tweaks
- Straightforward additions

## BMad Commands in Claude Code
```bash
# Available agents
/BMad:agents:analyst       # Mary - Research, brainstorming
/BMad:agents:pm           # Emily - Requirements (PRDs)
/BMad:agents:architect    # Michael - Technical design
/BMad:agents:ux-expert    # Sofia - UI/UX (rarely needed here)
/BMad:agents:po           # David - Story management
/BMad:agents:sm           # Sarah - Story drafting
/BMad:agents:dev          # James - Implementation
/BMad:agents:qa           # Linda - Code review

# Special agents
/BMad:agents:bmad-master      # Learn BMad workflows
/BMad:agents:bmad-orchestrator # Coordinate agents

# Tools
bmad-flatten    # Export codebase as XML for AI
bmad-install    # Update BMad installation
```

### Inside Each Agent
```bash
*help                 # Show agent-specific commands
*exit                 # Leave agent mode

# Common commands by agent:
# Analyst
*brainstorm {topic}   # Structured ideation
*elicit               # Deep requirements discovery

# PM
*create-brownfield-prd  # For existing projects

# Architect  
*document-project     # Analyze & document codebase
*create-brownfield-architecture

# PO
*shard-prd           # Break PRD into epics/stories
*shard-architecture  # Break architecture into pieces

# Dev
*create-bug-fix      # Quick fix workflow
*implement-story     # Full story implementation
```

## Brownfield Workflows for nix-config

### 1. Document Current State (First Time)
```bash
# Already done, but for reference:
/BMad:agents:architect
*document-project
# Creates comprehensive architecture.md
```

### 2. Research & Plan Feature
```bash
# Research phase
/BMad:agents:analyst
*brainstorm "simplifying nix-config theming system"
*elicit  # Dig deeper into requirements

# Requirements phase  
/BMad:agents:pm
*create-brownfield-prd
# Define what we're changing and why

# Technical design
/BMad:agents:architect
*create-brownfield-architecture
# How to implement the changes
```

### 3. Complex Debug (e.g., Colima Issue)
```bash
/BMad:agents:analyst
*research-prompt "colima docker memory allocation lima vm"

/BMad:agents:dev
*create-bug-fix
# Provides context about 16GB→2GB issue
```

### 4. Implement Changes
```bash
# After planning, break down work
/BMad:agents:po
*shard-prd  # Creates epic files in docs/prd/
*shard-architecture  # Creates detail files

# Create stories
/BMad:agents:sm
*create-brownfield-story
# Drafts implementation story

# Implement
/BMad:agents:dev
*implement-story docs/stories/story-001.md
# Follow tasks sequentially
```

## BMad Project Configuration

BMad looks for configuration in `.bmad-core/core-config.yaml`:

```yaml
# Document locations
prd:
  prdFile: docs/prd.md
  prdSharded: true
  prdShardedLocation: docs/prd
architecture:
  architectureFile: docs/architecture.md
  architectureSharded: true
  architectureShardedLocation: docs/architecture

# Development settings
devStoryLocation: docs/stories
devLoadAlwaysFiles:  # Files dev agent always loads
  - docs/architecture/coding-standards.md
  - docs/architecture/tech-stack.md
  - docs/architecture/source-tree.md
```

## Integration Tips

1. **Flatten codebase** - Use `bmad-flatten` to create XML for AI context
2. **Document first** - Use architect agent to understand existing code
3. **Follow patterns** - BMad agents will learn from your existing code structure
4. **Update docs** - Keep architecture.md current after major changes

## Quick Decision Tree

```
Need to understand existing code? → /BMad:agents:architect *document-project
Planning a multi-file feature? → Start with /BMad:agents:analyst or /BMad:agents:pm
Have a complex bug? → /BMad:agents:dev *create-bug-fix
Refactoring architecture? → Full BMad workflow (PM → Architect → PO → Dev)
Simple one-file change? → Skip BMad, just make the change
```

---

*Remember: BMad is a tool. Use it when it adds value, skip when it adds overhead.*