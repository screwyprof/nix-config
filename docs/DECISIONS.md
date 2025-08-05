# Decision Journal

A chronological record of decisions made in nix-config, capturing what sparked each change, the journey to solution, and lessons learned.

**Note**: Currently maintained manually. See [briefs/003-decision-journal.md](briefs/003-decision-journal.md) for the planned AI-assisted capture system that will automate this process.

This decision journal captures the "why" behind changes - the problems, explorations, and solutions. Each entry follows the format from feature 003's brief, emphasizing natural language and practical lessons.

Unlike a CHANGELOG (version releases), this journal focuses on the development journey and decision rationale. Once feature 003 is implemented, these entries will be captured automatically during work sessions.

---

## 001: Integrate BMad-Method for structured AI development

**Feature**: [001-bmad-integration](features/001-bmad-integration.md)

**What sparked this:** Needed a structured approach to AI-assisted development but kept getting lost in complex features without clear workflow.

**The journey:** Started exploring various AI agent frameworks. Found BMad-Method which provides clear agent roles (Analyst, PM, Architect, Dev) and workflows for both new projects and existing codebases.

**What we tried:**
1. Ad-hoc AI assistance → Too unstructured, kept losing context
2. Custom agent definitions → Too much work to maintain
3. BMad-Method v4.34.0 → Perfect balance of structure and flexibility

**Outcome:** Packaged BMad as nix derivation, integrated with Claude Code, now have systematic approach to complex features.

**Future Me Notes:** When tackling complex features, start with `/BMad:agents:analyst` for brainstorming. Don't try to use all agents for simple tasks - that's overkill.

---

## 002: Create documentation organization system

**Feature**: [002-organize-docs](features/002-organize-docs.md)

**What sparked this:** BMad is great but seemed like overkill for simple nix-config changes. Needed a way to track feature evolution while skipping unnecessary ceremony.

**The journey:** Started with analyst agent brainstorming session. Explored multiple folder structures, discovered BMad agents accept custom file paths (game changer!). Realized we need both structure and flexibility.

**What we tried:**
1. Pure BMad structure → Too enterprise-heavy for personal project
2. Flat decision log → Lost feature evolution tracking
3. Hybrid features/ + BMad dirs → Perfect balance

**Outcome:** Created `features/` for evolution tracking, each feature gets README with status checklist, BMad dirs used only when beneficial.

**Future Me Notes:** Not every feature needs full BMad flow. Use the checklist in feature READMEs to track what you actually used. Brief is minimum requirement.


---
