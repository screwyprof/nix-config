# BMad Guide for Backend & CLI Development

## Recommended Workflows

### For Backend/API Development

Use **`greenfield-service`** or **`brownfield-service`** workflows:

```bash
# Web UI Phase
*bmad-orchestrator
*workflow greenfield-service  # For new projects
# OR
*workflow brownfield-service  # For existing projects
```

### For CLI Tools

CLI tools are essentially backend services, so use the same **service workflows**. The architecture will focus on command structure rather than API endpoints.

## Backend/CLI Planning Phase

### 1. Project Brief (Analyst)
```bash
*analyst
*create-project-brief
```

Focus your brief on:
- **Backend**: API endpoints, data models, integrations
- **CLI**: Commands, flags, configuration, workflows

### 2. PRD Creation (PM)
```bash
*pm
*create-prd
```

The PRD will emphasize:
- **Backend**: RESTful/GraphQL endpoints, authentication, data flow
- **CLI**: Command structure, user workflows, configuration management

### 3. Architecture (Architect)
```bash
*architect
*create-architecture
```

Architecture focuses on:
- **Backend**: Service architecture, database design, API patterns
- **CLI**: Command parsing, plugin architecture, configuration layers

## Key Differences from Full-Stack

### 1. **No Frontend Components**
- No UX expert needed
- No UI/frontend architecture
- Focus purely on service layer

### 2. **Simplified Team**
```yaml
Recommended agents:
- analyst: Requirements gathering
- pm: Service specifications  
- architect: Backend architecture
- sm: Story creation
- dev: Implementation
- qa: Code review (optional)
```

### 3. **Architecture Templates**
BMad provides specific templates for backend:
- `architecture-tmpl.yaml` - General backend architecture
- Consider API-first design patterns
- Focus on data models and service boundaries

## Backend-Specific Best Practices

### API Development
```bash
# In your project brief, specify:
- API type (REST, GraphQL, gRPC)
- Authentication method (JWT, OAuth, API keys)
- Rate limiting requirements
- Versioning strategy
```

### Microservices
```bash
# Architecture should define:
- Service boundaries
- Inter-service communication
- Shared data strategies
- Deployment considerations
```

### CLI Tools
```bash
# Brief should include:
- Command structure (git-style subcommands?)
- Configuration management (files, env vars)
- Output formats (json, yaml, human-readable)
- Plugin/extension system
```

## Example: Backend API Project

### Phase 1: Planning (Web UI)
```bash
# 1. Start with orchestrator
*bmad-orchestrator
*workflow greenfield-service

# 2. Create project brief
*analyst
*create-project-brief
# Focus on: API endpoints, data models, integrations

# 3. Create PRD
*pm
*create-prd
# Detail each endpoint, request/response formats

# 4. Create architecture
*architect
*create-architecture
# Design service layers, database schema, API patterns

# 5. Validate
*po
*run-master-checklist
```

### Phase 2: Development (IDE)
```bash
# 1. Shard documents
#po
*shard-doc epics
*shard-doc architecture

# 2. Create stories
#sm
*create-next-story
# Stories focus on: endpoints, services, data layer

# 3. Implement
#dev
# Implement API endpoints, services, tests

# 4. Review (optional)
#qa
*review-story
```

## Example: CLI Tool Project

### Planning Adjustments
```bash
*analyst
*create-project-brief
# Focus on:
# - Command structure (myapp init, myapp deploy)
# - Configuration management
# - User workflows
```

### Story Examples
Stories for CLI tools typically include:
- Command implementation (one command per story)
- Configuration system setup
- Error handling and user feedback
- Documentation and help system

## Backend/CLI Specific Considerations

### 1. **Testing Strategy**
- Unit tests for services
- Integration tests for APIs
- E2E tests for CLI commands

### 2. **Documentation**
- API documentation (OpenAPI/Swagger)
- CLI help text and man pages
- Service architecture diagrams

### 3. **Deployment**
- Container strategies
- Configuration management
- Monitoring and logging

## Quick Decision Guide

```
What are you building?
├─ REST API?
│   └─ Use greenfield-service workflow
│
├─ GraphQL API?
│   └─ Use greenfield-service workflow
│
├─ Microservice?
│   └─ Use greenfield-service workflow
│
├─ CLI Tool?
│   └─ Use greenfield-service workflow
│       (Focus on commands vs endpoints)
│
├─ Adding to existing backend?
│   └─ Use brownfield-service workflow
│
└─ Simple script/prototype?
    └─ Consider starting directly with Dev agent
```

## Nix-Specific Integration

Since you're using nix-config:
```bash
# Your CLI tools can be packaged as nix packages
# After development, create a nix derivation:
./pkgs/my-cli-tool/default.nix

# BMad can help generate the initial structure
# Include in your stories:
# - Nix packaging requirements
# - Installation via nix-env or home-manager
```