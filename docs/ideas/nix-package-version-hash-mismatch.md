# NPM Package Version-Hash Mismatch Problem in buildNpmPackage

## The Problem

When updating an NPM package version in `buildNpmPackage` without updating the hashes, Nix silently uses the old cached version. This is extremely confusing:

1. You update `version = "4.35.3"`
2. Keep the old hash `sha256-OLD...`
3. Run `nix-rebuild` and it "succeeds"
4. But you're actually running the OLD version!

No warnings, no errors - just the wrong version.

## Why It Happens

- Nix prioritizes the hash (content-addressable)
- The `version` field is just metadata
- If Nix finds content matching the hash in store/cache, it uses that
- Never even attempts to fetch the new version

## Specific to buildNpmPackage

In `buildNpmPackage`, there are TWO hashes that need updating:

1. `hash` - for the source code (`fetchFromGitHub`)
2. `npmDepsHash` - for the NPM dependencies

Both can cause this silent failure if not updated when version changes.

## Potential Solutions

### 1. Automated Hash Update

- Create a wrapper around fetchFromGitHub that checks version vs hash
- Could warn or auto-update when mismatch detected
- Might need to hook into Nix evaluation

### 2. Flake Inputs Approach

- Use flake inputs for all external sources
- No manual hashes needed
- But changes workflow significantly

### 3. Overlay with Assertions

```nix
# Concept: assert hash matches version
fetchFromGitHub {
  rev = "v${version}";
  hash = assertHashMatchesVersion version expectedHash;
}
```

### 4. Linting Tool

- External tool to scan .nix files
- Check if version changes without hash changes in git diff
- Could be pre-commit hook or CI check

### 5. Different Fetcher Design

- Create new fetcher that fails if hash seems stale
- Maybe check commit date vs hash generation date?
- Or embed version in hash somehow

### 6. Nix Language Feature

- Propose upstream: warning when version changes but hash doesn't
- Or new fetchFromGitHub parameter: `warnOnVersionMismatch = true`

## Questions to Explore

1. Can we detect at eval time if a hash is "too old" for a version?
2. Is there a way to make Nix always verify fetches when version changes?
3. Could we create a "development mode" where hashes are always checked?
4. Would a different workflow (like nvfetcher) solve this better?
5. Do similar tools for rust for example have a similar issue?

## Trade-offs

- Convenience vs Reproducibility
- Extra complexity vs User experience  
- Breaking existing workflows vs Preventing mistakes

This is a fundamental tension in Nix - it's working as designed (reproducible), but the design surprises users who expect version to be authoritative.
