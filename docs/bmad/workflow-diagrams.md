# BMad Workflow Diagrams

## Overall BMad Method Flow

```mermaid
graph TD
    subgraph "Phase 1: Planning (Web UI)"
        A[Project Idea] --> B{New or Existing?}
        B -->|New| C[Greenfield Workflow]
        B -->|Existing| D[Brownfield Workflow]
        
        C --> E[Analyst: Brief]
        D --> F[Flatten Codebase]
        F --> G[Analyst: Document]
        
        E --> H[PM: PRD]
        G --> I[PM: Brownfield PRD]
        
        H --> J[Architect: Architecture]
        I --> K[Architect: Brownfield Arch]
        
        J --> L[PO: Validate]
        K --> L
    end
    
    subgraph "Transition"
        L --> M[Switch to IDE]
        M --> N[PO: Shard Documents]
    end
    
    subgraph "Phase 2: Development (IDE)"
        N --> O[SM: Create Story]
        O --> P[Dev: Implement]
        P --> Q{Need QA?}
        Q -->|Yes| R[QA: Review]
        Q -->|No| S[Complete]
        R --> S
        S --> T{More Stories?}
        T -->|Yes| O
        T -->|No| U[Project Complete]
    end
    
    style M fill:#f9ab00,color:#fff
    style U fill:#34a853,color:#fff
```

## Greenfield Planning Workflow

```mermaid
graph TD
    A[Start: Project Idea] --> B{Optional: Research?}
    B -->|Yes| C[Analyst: Market Research]
    B -->|No| D[Analyst: Project Brief]
    C --> D
    
    D --> E[Brief Created]
    E --> F[PM: Read Brief]
    F --> G[PM: Create PRD]
    
    G --> H[PRD Created]
    H --> I[Architect: Read PRD]
    I --> J[Architect: Create Architecture]
    
    J --> K[Architecture Created]
    K --> L[PO: Run Master Checklist]
    
    L --> M{Documents Aligned?}
    M -->|No| N[PO: Update Epics/Stories]
    N --> O[Update Docs as Needed]
    O --> L
    M -->|Yes| P[Planning Complete]
    
    P --> Q[📁 Switch to IDE]
    
    style P fill:#34a853,color:#fff
    style Q fill:#f9ab00,color:#fff
```

## Development Cycle Workflow

```mermaid
graph TD
    A[Start: Sharded Docs Ready] --> B[SM: Select Next Epic Chunk]
    B --> C[SM: Draft Story from Chunk]
    C --> D[Story File Created]
    
    D --> E{User Reviews Story}
    E -->|Changes Needed| C
    E -->|Approved| F[Dev: Read Story File]
    
    F --> G[Dev: Implement Code]
    G --> H[Dev: Complete Tasks]
    H --> I[Dev: Mark Ready]
    
    I --> J{User Verification}
    J -->|Changes Needed| G
    J -->|Request QA| K[QA: Review Story]
    J -->|Approve| M[Story Complete]
    
    K --> L{QA Results}
    L -->|Needs Work| G
    L -->|Approved| M
    
    M --> N{More Stories?}
    N -->|Yes| B
    N -->|No| O[Development Complete]
    
    style M fill:#34a853,color:#fff
    style O fill:#1a73e8,color:#fff
```

## Brownfield Workflow

```mermaid
graph TD
    A[Existing Codebase] --> B[Run bmad-flatten]
    B --> C[Flattened XML Created]
    
    C --> D[Analyst: Document Project]
    D --> E[Current State Documented]
    
    E --> F[Architect: Analyze Current]
    F --> G[Architect: Design Target State]
    G --> H[Brownfield Architecture Created]
    
    H --> I[PM: Read Architecture]
    I --> J[PM: Create Brownfield PRD]
    J --> K[PRD with Constraints]
    
    K --> L[PO: Create Brownfield Epic]
    L --> M[Epic Respecting Existing Code]
    
    M --> N[PO: Run Checklist]
    N --> O{Validated?}
    O -->|No| P[Adjust Documents]
    P --> N
    O -->|Yes| Q[Ready for Development]
    
    Q --> R[📁 Switch to IDE]
    R --> S[Use Brownfield Dev Cycle]
    
    style Q fill:#34a853,color:#fff
    style R fill:#f9ab00,color:#fff
```

## Story File Information Flow

```mermaid
graph LR
    subgraph "Document Sources"
        A[Sharded Epic]
        B[Sharded Architecture]
        C[Technical Preferences]
        D[Project Context]
    end
    
    subgraph "Story Creation"
        E[SM Reads Sources]
        F[SM Writes Story File]
        G[Story Contains:]
        H[- Implementation Context]
        I[- Code Examples]
        J[- Architecture Refs]
        K[- Acceptance Criteria]
    end
    
    subgraph "Implementation"
        L[Dev Reads Story]
        M[Everything Needed]
        N[No Context Loss]
    end
    
    A --> E
    B --> E
    C --> E
    D --> E
    E --> F
    F --> G
    G --> H
    G --> I
    G --> J
    G --> K
    F --> L
    L --> M
    M --> N
    
    style F fill:#f9ab00,color:#fff
    style N fill:#34a853,color:#fff
```

## Agent Activation Flow

```mermaid
graph TD
    A[User Input] --> B{Command Type?}
    
    B -->|*agent| C[Web UI Agent]
    B -->|#agent| D[IDE Agent]
    
    C --> E[Load Agent Definition]
    D --> E
    
    E --> F[Load Dependencies]
    F --> G[Activate Persona]
    G --> H[Ready for Commands]
    
    H --> I{User Command}
    I -->|Task| J[Execute Task]
    I -->|Template| K[Generate Document]
    I -->|Checklist| L[Run Validation]
    
    J --> M[Output Result]
    K --> M
    L --> M
    
    M --> N{Continue?}
    N -->|Yes| I
    N -->|No| O[*exit]
    
    style H fill:#34a853,color:#fff
```

## Context Management Strategy

```mermaid
graph TD
    subgraph "Planning Phase"
        A[Rich Context]
        B[Large Documents]
        C[Exploratory Work]
        D[Many Dependencies]
    end
    
    subgraph "Sharding Process"
        E[PO: Shard Epics]
        F[PO: Shard Architecture]
        G[Break into Chunks]
        H[Maintain References]
    end
    
    subgraph "Development Phase"
        I[Lean Context]
        J[One Story at Time]
        K[Complete Context in Story]
        L[Minimal Dependencies]
    end
    
    A --> E
    B --> F
    C --> G
    D --> H
    
    E --> I
    F --> J
    G --> K
    H --> L
    
    style G fill:#f9ab00,color:#fff
    style K fill:#34a853,color:#fff
```

## Quick Decision Flow

```mermaid
graph TD
    A[Start] --> B{Have BMad Installed?}
    B -->|No| C[Run bmad-install]
    B -->|Yes| D{New Project?}
    
    C --> D
    D -->|Yes| E[Use Greenfield]
    D -->|No| F[Use Brownfield]
    
    E --> G{Need Research?}
    G -->|Yes| H[Start with Analyst Brainstorm]
    G -->|No| I[Start with Project Brief]
    
    F --> J[Run bmad-flatten]
    J --> K[Document Current State]
    
    H --> L[Continue to Planning]
    I --> L
    K --> L
    
    L --> M[Create PRD & Architecture]
    M --> N[Validate & Shard]
    N --> O[Begin Development Cycle]
    
    style O fill:#34a853,color:#fff
```