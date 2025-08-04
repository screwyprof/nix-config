# BMad Agent Roles Reference

## Planning Phase Agents (Web UI)

### 🧑‍💼 BMad Orchestrator (`*bmad-orchestrator`)
**Role**: Workflow conductor and BMad expert
**When to use**: 
- Starting a new project
- Understanding BMad workflows
- Getting unstuck
- Choosing the right workflow

**Key commands**:
- `*workflow {type}` - Shows specific workflow diagram
- `*help` - Lists all available BMad commands

### 📊 Analyst (`*analyst`)
**Role**: Business analyst and ideation partner
**When to use**:
- Project inception
- Market research needed
- Brainstorming features
- Documenting existing systems

**Key commands**:
- `*create-project-brief` - Foundation document for new projects
- `*brainstorm {topic}` - Structured ideation session
- `*perform-market-research` - Competitive analysis
- `*document-project` - Capture existing system architecture

### 📋 Product Manager (`*pm`)
**Role**: Requirements definition and product strategy
**When to use**:
- After project brief is ready
- Need detailed product requirements
- Feature prioritization

**Key commands**:
- `*create-prd` - Generate PRD from project brief
- `*create-brownfield-prd` - PRD considering existing constraints

### 🏗️ Architect (`*architect`)
**Role**: Technical design and system architecture
**When to use**:
- After PRD is complete
- Need technical specifications
- System design decisions

**Key commands**:
- `*create-architecture` - Technical design from PRD
- `*create-brownfield-architecture` - Architecture for existing systems

### 👮 Product Owner (`*po`)
**Role**: Backlog management and document validation
**When to use**:
- Validating planning documents
- Preparing for development
- Breaking down large documents

**Key commands**:
- `*run-master-checklist` - Ensure all docs align
- `*shard-doc epics` - Break epics into manageable pieces
- `*shard-doc architecture` - Break architecture for context
- `*brownfield-create-epic` - Epics respecting existing code

## Development Phase Agents (IDE)

### 🏃 Scrum Master (`*sm`, `#sm`)
**Role**: Story creation and sprint management
**When to use**:
- Starting each development cycle
- Creating implementation stories
- Managing story flow

**Key commands**:
- `*create-next-story` - Draft next implementation story
- `*create-brownfield-story` - Story for existing codebases
- `*validate-next-story` - Ensure story completeness

### 💻 Developer (`*dev`, `#dev`)
**Role**: Code implementation
**When to use**:
- Implementing stories
- Writing actual code
- Completing development tasks

**Key behaviors**:
- Reads story file for full context
- Implements one story at a time
- Marks tasks complete when done
- Maintains code quality

### 🔍 QA (`*qa`, `#qa`)
**Role**: Code review and quality assurance
**When to use**:
- Complex story implementations
- Need senior developer review
- Code refactoring needed
- Knowledge transfer

**Key commands**:
- `*review-story` - Comprehensive code review
- Provides refactoring suggestions
- Ensures best practices
- Identifies potential issues

## Specialized Agents

### 🎨 UX Expert (`*ux-expert`)
**Role**: User experience design
**When to use**:
- Need UI/UX specifications
- Design system creation
- User flow definition

**Key outputs**:
- UI component specifications
- User journey maps
- Design system documentation

## Agent Selection Guide

```
What do you need?
├─ Starting new project?
│   └─ Use *bmad-orchestrator → *analyst
│
├─ Have an idea to develop?
│   └─ *analyst → *pm → *architect
│
├─ Ready to code?
│   └─ *po (shard) → *sm → *dev → *qa
│
├─ Working with existing code?
│   └─ *analyst (document) → brownfield agents
│
└─ Need guidance?
    └─ *bmad-orchestrator
```

## Agent Communication Pattern

Agents communicate through files, not directly:

1. **Analyst** writes `project-brief.md`
2. **PM** reads brief, writes `prd.md`
3. **Architect** reads PRD, writes `architecture.md`
4. **PO** validates all, shards documents
5. **SM** reads shards, writes `stories/S001.md`
6. **Dev** reads story, writes code
7. **QA** reads code, provides review

## Best Practices

1. **One agent at a time** - Don't mix agent contexts
2. **Follow the flow** - Planning → Development
3. **Trust the process** - Each agent builds on previous work
4. **Complete cycles** - Finish stories before starting new ones
5. **Use QA wisely** - Not every story needs QA review

## Web vs IDE Agent Usage

### Web UI Agents
- Rich context, exploratory
- Document generation focused
- Can handle large templates
- Good for planning and design

### IDE Agents  
- Lean context, execution focused
- Code generation focused
- Minimal dependencies
- Good for implementation