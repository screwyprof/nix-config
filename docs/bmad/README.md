# BMad Method Reference Guide for AI Agents

This directory contains BMad Method documentation optimized for AI agent consumption. The actual BMad core files are located in `.bmad-core/` at the project root.

## Quick Navigation

- [Workflow Cheat Sheet](./workflow-cheatsheet.md) - Quick command reference for greenfield and brownfield projects
- [Core Concepts](./core-concepts.md) - Understanding BMad's two-phase approach
- [Agent Roles](./agent-roles.md) - What each agent does and when to use them
- [Command Reference](./command-reference.md) - All available commands with the nix package
- [Workflow Diagrams](./workflow-diagrams.md) - Visual workflow representations

## BMad Installation Status

BMad Method is installed as a nix package in this project. Available commands:
- `bmad-method` or `bmad` - Main CLI tool
- `bmad-install` - Install BMad in a project
- `bmad-flatten` - Flatten codebase for AI analysis
- `bmad-build` - Build web bundles

## Key Principles for AI Agents

1. **Two-Phase Workflow**: Planning (Web UI) → Development (IDE)
2. **Context-Engineered Stories**: SM creates detailed stories, Dev implements them
3. **Sequential Development**: One story at a time, full context included
4. **Natural Language First**: Everything is markdown-based instructions