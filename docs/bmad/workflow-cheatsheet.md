# BMad Workflow Cheat Sheet

## 🟢 Greenfield Project (New Project)

### Phase 1: Planning (Web UI - Gemini/ChatGPT/Claude)

```bash
# 1. Start with BMad Orchestrator
*bmad-orchestrator
*workflow greenfield-fullstack  # Shows complete workflow

# 2. Optional: Research & Brainstorming
*analyst
*brainstorm {topic}
*perform-market-research

# 3. Create Core Documents
*analyst
*create-project-brief          # Foundation document

*pm 
*create-prd                    # Product Requirements from brief

*architect
*create-architecture           # Technical design from PRD

*po
*run-master-checklist          # Validate alignment
```

### Phase 2: Development (IDE - Cursor/VS Code/Claude Code)

```bash
# 1. Setup Project
bmad-install                   # Install BMad in project
cd docs/                       # Navigate to docs directory

# 2. Shard Documents
#po
*shard-doc epics              # Break down epics
*shard-doc architecture       # Break down architecture

# 3. Development Cycle (Repeat)
#sm
*create-next-story            # SM drafts detailed story

#dev
*implement                    # Dev implements story
*complete-tasks               # Mark tasks complete

#qa (optional)
*review-story                 # Senior review & refactoring

# Repeat until all stories complete
```

## 🏗️ Brownfield Project (Existing Code)

### Phase 1: Understanding & Planning

```bash
# 1. Analyze Existing Codebase
bmad-flatten --input . --output codebase.xml  # Flatten for AI analysis

# 2. Document Current State
*analyst
*document-project             # Capture existing architecture

*architect
*create-brownfield-architecture  # Document current + future state

*pm
*create-brownfield-prd        # Requirements considering constraints

# 3. Create Implementation Plan
*po
*brownfield-create-epic       # Epic considering existing code
*run-master-checklist         # Validate approach
```

### Phase 2: Incremental Development

```bash
# Same as greenfield but:
#sm
*create-brownfield-story      # Stories that respect existing code

#dev
# More careful implementation:
# - Check existing patterns first
# - Maintain backward compatibility
# - Update tests incrementally
```

## 🔑 Key Commands by Agent

### Analyst (*analyst)
- `*create-project-brief` - Start new project
- `*brainstorm {topic}` - Facilitate ideation
- `*perform-market-research` - Market analysis
- `*document-project` - Document existing project

### PM (*pm)
- `*create-prd` - Create Product Requirements Document
- `*create-brownfield-prd` - PRD for existing projects

### Architect (*architect)
- `*create-architecture` - Technical architecture
- `*create-brownfield-architecture` - Architecture for existing code

### PO (*po)
- `*run-master-checklist` - Validate all documents
- `*shard-doc {type}` - Break down large documents
- `*brownfield-create-epic` - Epic for existing projects

### SM (*sm)
- `*create-next-story` - Draft next implementation story
- `*create-brownfield-story` - Story respecting existing code

### Dev (*dev)
- `*implement` - Start implementing current story
- `*complete-tasks` - Mark story tasks complete

### QA (*qa)
- `*review-story` - Senior developer review

## 📌 Quick Decision Tree

```
New Project?
├─ YES → Use Greenfield workflow
│   ├─ Start with *analyst for brief
│   ├─ Then *pm for PRD
│   └─ Then *architect for technical design
│
└─ NO → Use Brownfield workflow
    ├─ Run bmad-flatten first
    ├─ Use *document-project
    └─ Create brownfield-specific docs
```

## 🚀 Nix Package Commands

```bash
# Installation & Setup
bmad-install                  # Install BMad in current project

# Utilities
bmad-flatten -i . -o out.xml  # Prepare codebase for AI
bmad-build                    # Build web bundles

# After installation in project
npm run install:bmad          # Update existing installation
```

## ⚡ Pro Tips

1. **Always validate** with `*run-master-checklist` before development
2. **One story at a time** - Dev should complete before SM creates next
3. **Shard large docs** - Better context management for AI
4. **Use QA sparingly** - Only for complex or critical stories
5. **Document state first** in brownfield projects