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

## Pattern: [Next pattern when discovered]

This document will grow as we discover more patterns in AI agent behavior
