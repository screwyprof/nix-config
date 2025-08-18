# AI Agents Lessons Learned

Patterns and failures observed while working with AI agents (Claude Code, BMad agents, etc).

---

## Pattern: Substitution Instead of Failure Acknowledgment

**Observed:** When primary methods fail, AI agents often substitute inappropriate alternatives rather than acknowledging the failure.

### Case 1: Command Timeout → Wrong Data Source

**Date:** 2025-08-17 (Story 1.2 implementation)

**What happened:**

1. Asked to run `nix-store-size` to check disk usage
2. Correctly identified it as alias to `du -sh /nix/store`
3. Command timed out after 2 minutes
4. **Failure:** Used `df -h /nix` output instead (showing partition size)
5. Reported "160GB" when actual was "54GB" (3x error)

**Root cause:** When expected command failed, substituted conceptually related but fundamentally different data.

### Case 2: Format Mismatch → Forced Comparison

**Date:** 2025-08-17 (Story 1.2 implementation)

**What happened:**

1. Needed to compare gc-roots before/after states
2. "Before" file had detailed sections and headers
3. "After" file had basic ls output only
4. **Failure:** Tried to run diff anyway, producing meaningless output
5. User intervention: "comparing apples and oranges"

**Root cause:** When data formats didn't match, attempted forced comparison instead of acknowledging incompatibility.

### Pattern Analysis

Both cases show the same anti-pattern:

- **Expected path blocked** (timeout, format mismatch)
- **Find "related" alternative** (df for du, diff for incompatible formats)
- **Present as valid result** without caveat
- **User must catch the error**

### Mitigation Strategies

1. **For users:** Always verify AI-provided data, especially after signs of difficulty
2. **For prompts:** Explicitly instruct to acknowledge failures rather than substitute
3. **Red flags:** Watch for phrases like "let me try different approach" followed by immediate results

---

## Pattern: Stating Assumptions as Facts

**Observed:** AI agents make claims without verification, requiring user correction.

### Case 1: FDA and Read-Only Filesystems

**Date:** 2025-08-18 (Story 1.4 investigation)

**What happened:**

1. Claimed FDA allows modifying "read-only filesystems"
2. User questioned: "But /nix/store is also a read only file system, isn't it"
3. **Failure:** Never verified mount status before making claim
4. Investigation revealed: `/nix` has "protect" flag, NOT read-only mount
5. Had to correct misleading statements

**Root cause:** Assumed technical details without checking actual system state.

### Mitigation

- Always run verification commands before technical claims
- Check mount flags, permissions, actual system state
- Present findings with evidence, not assumptions

---

## Pattern: Narrow Investigation Scope

**Observed:** AI agents stop at first finding instead of comprehensive search.

### Case 1: Hardcoded Store Paths

**Date:** 2025-08-18 (Story 1.4 investigation)

**What happened:**

1. Found store path in `.zimrc` file
2. Initially stopped investigation there
3. User prompted broader search
4. **Reality:** Found 49 symlinks + multiple config files with embedded paths
5. Missed the full pattern scope initially

**Root cause:** Satisfaction with first discovery prevents comprehensive investigation.

### Mitigation

- Always search broadly first: `find ~/.config ~/.local ~/.cache`
- Quantify findings: "Found X instances across Y files"
- Look for patterns, not just single instances

---

## Pattern: Missing Command Documentation

**Observed:** AI agents present findings without showing how they were obtained.

### Case 1: Investigation Without Evidence Trail

**Date:** 2025-08-18 (Story 1.4 investigation)

**What happened:**

1. Showed chmod test results without commands
2. Claimed FDA behavior without test evidence
3. User repeatedly asked: "capture commands/output when it's important"
4. **Failure:** Created non-reproducible investigation
5. Had to retroactively add command documentation

**Root cause:** Focus on conclusions over methodology.

### Mitigation

- Always show: command → output → conclusion
- Make investigations reproducible
- Include full context (user vs sudo, FDA status, etc.)

---

## Pattern: Accepting Initial Hypothesis

**Observed:** AI agents stick to user's initial framing even when evidence contradicts.

### Case 1: Execution Order vs Environment

**Date:** 2025-08-18 (Story 1.4 investigation)

**What happened:**

1. User said: "The key is the execution order"
2. Investigation showed it's about execution environment (FDA vs no FDA)
3. User corrected: "it's not ONLY execution order but about different execution environment"
4. **Success:** Presented findings that respectfully contradicted initial assumption

**Root cause:** Over-deference to user's initial problem statement.

### Mitigation

- Investigate thoroughly before accepting explanations
- Present evidence-based findings even if they contradict
- Be respectful but truthful about discoveries

---

## Pattern: Not Using Available Resources

**Observed:** AI agents dive into investigation without checking existing documentation.

### Case 1: Redundant Investigation

**Date:** 2025-08-18 (Story 1.4 investigation)

**What happened:**

1. Started investigating from scratch
2. User: "But you have that info in the report"
3. Later: "search first in the summary"
4. **Failure:** Wasted effort on already-documented findings
5. Summary had key insights like `/bin/wait4path` needing FDA

**Root cause:** Action bias - preferring to investigate over reading existing docs.

### Mitigation

- Always check existing documentation first
- Read summaries, reports, prior investigations
- Build on existing knowledge, don't duplicate

---

## Pattern: Incomplete Investigation Closure

**Observed:** AI agents don't acknowledge when questions remain unanswered.

### Case 1: Unanswered Architecture Questions

**Date:** 2025-08-18 (Story 1.4 investigation)

**What happened:**

1. Several questions couldn't be answered despite investigation
2. No Apple documentation for "protect" mount flag
3. Home Manager design decisions unclear
4. **Success:** Documented these as "Unanswered Questions" section
5. Provided value by being honest about limitations

**Root cause:** Pressure to provide complete answers.

### Mitigation

- It's okay to have unanswered questions
- Document what you tried and why it failed
- Distinguish "we found" from "we couldn't determine"

---

## Pattern: [Next pattern when discovered]

This document will grow as we discover more patterns in AI agent behavior
