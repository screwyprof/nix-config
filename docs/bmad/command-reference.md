# BMad Command Reference

## Nix Package Commands

Since BMad is installed as a nix package, these commands are available system-wide:

### Primary Commands

```bash
bmad-method [command]          # Main BMad CLI
bmad [command]                 # Alias for bmad-method
```

### Convenience Wrappers

```bash
bmad-install                   # Install BMad in current project
bmad-flatten                   # Flatten codebase for AI analysis  
bmad-build                     # Build web bundles for AI platforms
```

### Command Usage Examples

#### Install BMad in a Project
```bash
cd /path/to/your/project
bmad-install

# This creates:
# - .bmad-core/ directory with all agents and resources
# - Updates package.json with BMad scripts
# - Sets up the project for BMad workflow
```

#### Flatten Codebase for AI Analysis
```bash
# Basic usage - creates flattened-codebase.xml
bmad-flatten

# Specify input directory
bmad-flatten --input /path/to/source

# Specify output file
bmad-flatten --output my-project.xml

# Full example
bmad-flatten --input ./src --output ./analysis/codebase.xml
```

#### Build Web Bundles
```bash
# Build all team bundles
bmad-build

# Builds bundles in dist/ directory:
# - team-fullstack.txt
# - team-no-ui.txt
# - individual agent bundles
```

## Project-Level Commands

After running `bmad-install` in a project, these npm scripts become available:

```bash
npm run install:bmad           # Update BMad installation
npm run bmad:build             # Build web bundles
npm run bmad:flatten           # Flatten current project
```

## Agent Commands Reference

### Universal Commands (All Agents)

```bash
*help                          # Show agent-specific commands
*exit                          # Leave current agent mode
```

### BMad Orchestrator
```bash
*bmad-orchestrator             # Activate orchestrator
*workflow {type}               # Show workflow diagram
  - greenfield-fullstack
  - greenfield-service
  - greenfield-ui
  - brownfield-fullstack
  - brownfield-service
  - brownfield-ui
```

### Analyst Commands
```bash
*analyst                       # Activate analyst
*create-project-brief          # New project foundation
*brainstorm {topic}           # Facilitated ideation
*perform-market-research       # Market analysis
*create-competitor-analysis    # Competitive landscape
*document-project             # Document existing system
*research-prompt {topic}      # Deep research prompts
```

### PM Commands
```bash
*pm                           # Activate PM
*create-prd                   # Create PRD from brief
*create-brownfield-prd        # PRD for existing system
```

### Architect Commands
```bash
*architect                    # Activate architect
*create-architecture          # Technical architecture
*create-brownfield-architecture # Architecture for existing
*create-front-end-architecture # Frontend-specific design
*create-fullstack-architecture # Full stack design
```

### Product Owner Commands
```bash
*po                          # Activate PO
*run-master-checklist        # Validate all documents
*shard-doc {type}           # Break down documents
  - epics                    # Shard epic documents
  - architecture            # Shard architecture
  - prd                     # Shard PRD
*brownfield-create-epic      # Epic for existing code
*validate-next-story        # Check story completeness
```

### Scrum Master Commands
```bash
*sm OR #sm                   # Activate SM
*create-next-story          # Draft implementation story
*create-brownfield-story    # Story for existing code
*validate-next-story        # Ensure story ready
*correct-course             # Adjust approach
```

### Developer Commands
```bash
*dev OR #dev                # Activate developer
# No explicit commands - dev reads stories and implements
```

### QA Commands
```bash
*qa OR #qa                  # Activate QA
*review-story              # Senior developer review
```

### UX Expert Commands
```bash
*ux-expert                 # Activate UX expert
*create-ux-specifications  # UI/UX specifications
```

## Command Patterns

### Planning Phase Pattern (Web UI)
```bash
1. *bmad-orchestrator
2. *workflow greenfield-fullstack
3. *analyst
4. *create-project-brief
5. *pm
6. *create-prd
7. *architect  
8. *create-architecture
9. *po
10. *run-master-checklist
```

### Development Phase Pattern (IDE)
```bash
1. cd docs/
2. #po
3. *shard-doc epics
4. *shard-doc architecture
5. #sm
6. *create-next-story
7. #dev
8. (implement the story)
9. #qa (optional)
10. *review-story
```

### Brownfield Pattern
```bash
1. bmad-flatten
2. *analyst
3. *document-project
4. *architect
5. *create-brownfield-architecture
6. *pm
7. *create-brownfield-prd
8. #po
9. *brownfield-create-epic
10. #sm
11. *create-brownfield-story
```

## Tips and Tricks

1. **Use hash (#) in IDEs**: `#sm` is faster than `*sm` in IDE environments
2. **Chain commands**: You can activate agent and run command together: `*analyst create-project-brief`
3. **Flatten before brownfield**: Always run `bmad-flatten` before documenting existing projects
4. **Validate often**: Use `*run-master-checklist` to ensure document alignment
5. **One story at a time**: Complete current story before creating next