# Universal Document Refinement Principles for AI Agents

**Purpose:** Guidelines for AI agents when refining, analyzing, or creating technical documents in collaboration with humans.

## Core Principles

### 1. Honesty Over Polish

- State what was actually done, not what sounds impressive
- "Analyzed existing documents" not "Conducted comprehensive investigation"
- "Created summary from multiple sources" not "Performed exhaustive research"

### 2. Context Without History

- In handoffs, provide only what the next person needs
- Skip your completion journey ("I first did X, then Y")
- Focus on the current state and next actions

### 3. Examples Not Instructions

- When suggesting approaches: "One approach might be..." not "You must..."
- Respect that the recipient may have better ideas
- Provide options, not prescriptions unless specifically asked.

### 4. Fix Format Issues Before Claiming Ready

- If the document type has automated checks (linters, spell check), run them
- Don't claim "ready" or "complete" with known issues
- Address all warnings before declaring done

### 5. Define Domain-Specific Terms

- Every field has jargon - explain it where it's used
- Include what it does and where it's defined/configured
- Don't assume the reader shares your context

### 6. Mark Assumptions Clearly

- Use indicators like "⚠️ Assumed but not verified"
- Distinguish "we believe" from "we confirmed"
- Be explicit about what needs validation

### 7. Include Content, Not References Unlesss Specified Otherwise

- Show the actual commands, not "see section X"
- Include the relevant excerpt, not "as documented elsewhere"
- Make each section as self-contained as reasonable

### 8. Question Stated Constraints

- "2-3 pages" - is this firm or guidance?
- "Executive brief" - what does this mean in this context?
- Clarify before assuming

### 9. Remove Temporal References

- Don't reference temporary files or ephemeral state
- Make documents work regardless of when they're read
- Include necessary context within the document

### 10. Use Systematic Thinking

- Check your work methodically before claiming complete
- Use sequential thinking to catch oversights
- Verify claims against source material

### 11. Respect Existing Systems

- If referring to system commands/configs, note where they're defined
- Distinguish between one-off fixes and permanent changes
- Consider impact on existing workflows

### 12. Real Examples Clarify Abstract Concepts

- "User recovered 200GB" makes impact clearer than "significant disk usage"
- Concrete scenarios help readers understand severity
- Balance technical accuracy with relatable outcomes

### 13. Test Before Documenting

- Run commands to verify output before claiming they work
- Update expected results based on actual behavior
- Include test context: WHO ran it (user vs sudo) and WHY
- Don't assume theoretical output matches reality

### 14. Extend Before Creating

- Always check if content belongs in an existing section first
- Add to existing sections rather than creating new ones
- Only create new sections when content doesn't fit anywhere
- This reduces complexity, duplication, and maintains coherence

### 15. Question Value Claims

- When marking something "valuable", specify for what purpose
- "Nice to have" vs "Critical for X" provides clearer guidance
- Distinguish between different use cases and their requirements

### 15. Iterative Implementation Beats Batch Updates

- Fix-as-you-go prevents duplicate work
- Implement recommendations section by section
- Each iteration builds on previous improvements
- Avoids overwhelming batch changes that miss nuances

## When Working With Humans

### Communication Patterns

- Humans may correct your approach - adapt quickly
- If told you're "being obtuse" or "difficult", think harder or ask for clarification when in doubt
- Direct language often means drop the formalities

### Conciseness Over Verbosity

- Express ideas DRY, CLEAN, KISS - simple but not primitive
- Capture all important bits but avoid "water"
- Don't write poems when one line suffices
- Avoid selling/praising tools that are just utilities
- Skip fluff, keep substance

### Document Iteration

- Each revision should improve clarity, not just add content
- If something is removed, there's usually a good reason
- Ask for clarification rather than assuming intent

### Quality Checks

- Can someone unfamiliar with the project understand this?
- Are all claims verifiable?
- Is the document self-contained enough to be useful later?

### The "Pro Bono" Pattern

When you want to plant seeds for future improvements without commitment:

**Pattern:**

```markdown
**Pro Bono:** [Brief mention of possibility]
```

**Examples:**

- "Pro Bono: Could support configuration for this"
- "Pro Bono: Might benefit from automated checks"
- "Pro Bono: State tracking could help here"

**Why it works:**

- Non-threatening suggestion
- Shows forward thinking
- Doesn't demand action
- Plants seeds for future discussion
- Allows ideas to marinate

## Anti-Patterns to Avoid

1. **Corporate Language**: "Leveraging synergies" → "Using X with Y"
2. **False Completeness**: Claiming done while issues remain
3. **Assumption Stacking**: Building conclusions on unverified premises
4. **Context Dumping**: Including history that doesn't help the current task
5. **Over-Prescription**: Telling experts how to do their job
6. **Jargon Walls**: Using terms without explanation
7. **Reference Mazes**: Making readers jump between documents for basic info
8. **Time Travel Writing**: "Has been completed" for future events → "To be completed"
9. **Ambiguous References**: "This document" → Use explicit paths
10. **Template Ignorance**: Creating custom formats when templates exist
11. **Untested Commands**: Including commands without verifying they work
12. **Vague Value Claims**: "This is valuable" → "Valuable for debugging X"
13. **Batch Documentation**: Waiting to document everything at once
14. **Pompous Context**: "real-world brownfield development" → "existing personal project"
15. **Inconsistent Formatting**: Mixing styles arbitrarily → Pick one and stick to it
16. **Title Mismatch**: Title doesn't reflect actual content → Ensure title matches document purpose

## Lessons from Multi-Agent Systems

### 16. Assume No Shared Context

In multi-agent or multi-person systems:

- Be explicit with file paths and references
- Don't use "this" or "that" without clear antecedents
- Include full context in prompts and handoffs
- Example: Not "from this PRD" but "from `./prd/specific-file.md`"

### 17. Time Context Matters

When writing about sequenced events:

- Use future tense for things not yet done
- Add temporal markers: "After X completes", "Before starting Y"
- Avoid present perfect for future events
- Be clear about prerequisites and dependencies

### 18. Templates Exist for Compatibility

Before creating any document:

- Check if a template exists
- Use templates even in "fast" modes
- Understand template purpose before deviating
- Document any necessary template adaptations

### 19. Brief ≠ Comprehensive

A brief should be:

- 1-3 pages maximum
- Executive summary with links
- NOT a duplicate of detailed documentation
- Clear about what it references vs contains

### 20. Markdown Formatting Standards

For technical documentation:

- Use backticks for:
  - Technical product/system names: `BMad`, `Nix`, `Git`
  - Commands: `*draft`, `nix-rebuild-host`
  - Filenames and paths: `prd.md`, `core-config.yaml`
  - Code values: `true`, `false`, `null`
  - Technical terms that need emphasis or clarity
- Don't use backticks for:
  - Standard acronyms: API, URL, CEO, PM (unless context-specific)
  - Regular English words
- For markdown links, follow GitHub standards:
  - Standard links: `[BMad](url)` - no backticks in link text
  - Code/file links: ``[`config.yaml`](url)`` - backticks only for actual code/commands
  - Good: `[document-refinement-principles](/docs/ideas/document-refinement-principles.md)` (absolute)
  - Good: `[lessons-learned.md](./lessons-learned.md)` (same folder)
  - Good: `[agent-reference.md](bmad/agent-reference.md)` (subfolder)
  - Bad: ``[`document-refinement-principles`](url)`` (not code, shouldn't have backticks)
  - Bad: "see document-refinement-principles" (use proper link)
  - Bad: `document-refinement-principles.md` (when file exists, make it a link)
  - Bad: [document-refinement-principles](../../document-refinement-principles.md) (avoid ../)
- Prefer absolute paths from project root for clarity
- Relative paths are OK within same folder or to subfolders
- Avoid `../` paths that traverse up directories
- Only use backticks without links for files that don't exist yet or for technical terms

#### GitHub Compatibility

- For line references in GitHub: Use `#L100` format instead of `:100`
  - Good: `[example](../../../.bmad-core/workflows/greenfield-ui.yaml#L100)`
  - Bad: `[example](.bmad-core/workflows/greenfield-ui.yaml:100)`
- GitHub prefers relative paths for portability across forks/clones
- Absolute paths should be from repository root (not filesystem root)

#### Styling Consistency

- Context determines formatting:
  - BMad agents in text: `PM` said, the `SM` agent
  - BMad agents in emphasized lists: **`PM`** created PRD (both OK when emphasis needed)
  - General acronyms: The PM (project manager), CEO, API
- Avoid overuse of backticks:
  - Good: "The `PM` agent creates a `PRD`"
  - Bad: "The `PM` `agent` `creates` a `PRD`"
- Self-referencing files don't need links:
  - Good: **README.md** - This file
  - Bad: **[README.md](./README.md)** - This file
- Be consistent within a document - if you start using `PM` for BMad agents, continue throughout

### 21. Document Refinement Process

When refining existing documents:

- **Verify Claims**: Check every assertion against source material
- **Question Your Own Rules**: Be willing to correct inconsistencies in your own guidelines
- **User Feedback is Gold**: "You're contradicting yourself" → Fix it immediately
- **Iterative Improvement**: Each pass should make the document clearer
- **Evidence-Based Changes**: Support changes with concrete examples
- **Soften Absolute Language**: "Templates have gaps" → "Templates could benefit from..."
- **Context Matters**: Technical accuracy vs. audience understanding (e.g., "brownfield" may be correct but confusing)

#### Refinement Workflow

1. **Section by Section**: Don't rush - refine one section at a time
2. **Cross-Reference**: Check claims against multiple sources
3. **Fact-Check**: Verify against actual files/code
4. **Present Findings**: Show what was verified/corrected
5. **Get Approval**: Ask "Should I proceed?" before moving on

#### Signs You Need Refinement

- Titles that don't match content
- Claims without evidence
- Inconsistent formatting
- Jargon without explanation
- Absolute statements that aren't always true
- Missing context for assertions

## Remember

The goal is clear, actionable, honest documentation that helps the next person (human or AI) accomplish their task efficiently. When in doubt, err on the side of clarity and completeness over brevity.
