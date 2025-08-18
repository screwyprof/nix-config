# ⚠️ DRAFT - INVALID POSTMORTEM

**This postmortem was created before investigation was complete. Do not rely on its findings.**

See `docs/stories/1.4-investigation-report.md` for investigation gaps that must be filled first.

---

# Nix GC Removes Current Settings - Postmortem [DRAFT]

## Problem

Weekly automatic garbage collection via launchd consistently deletes user Zsh/P10k configurations, causing the P10k wizard to appear on next terminal launch. Manual rebuild with `nix-rebuild-host` temporarily fixes it until the next GC cycle.

## Reproduction

Successfully reproduced with this sequence:

1. Terminal with Full Disk Access enabled (iTerm2)
2. Run manual GC: `sudo -H nix-collect-garbage --delete-older-than 7d && sudo -H nix store optimise`
3. Trigger launchd GC: `sudo launchctl kickstart -k system/org.nixos.nix-gc`
4. Open new terminal → P10k wizard appears

## Evidence

### What Got Deleted

The critical store path `/nix/store/mfkixld2qzjijisc847ppymyx53irisx-source/` containing P10k configuration was garbage collected despite being actively referenced in:
- `~/.config/zsh/.zim/init.zsh:21` - sourcing p10k.zsh
- `~/.config/zsh/.zimrc:22` - zmodule reference
- P10k cache files

### GC Behavior

Both manual and launchd GC run as root and only target:
- `/nix/var/nix/profiles/per-user/root/*`
- `/nix/var/nix/profiles/system`
- Unreachable store paths

They do NOT directly touch user profiles in `~/.local/state/nix/profiles/`.

## Root Cause

The bug occurs due to a combination of factors:

1. **Missing transitive GC roots**: Home Manager protects its generation but not all store paths referenced in config files
2. **FDA permission differences**: Manual GC with FDA can remove .app bundles that launchd cannot
3. **Two-stage deletion**: Manual GC clears obstacles, allowing launchd to complete and delete unrooted paths

Key insight: The store path `/nix/store/mfkixld2qzjijisc847ppymyx53irisx-source/` containing P10k config was deleted because it was referenced in `.zimrc` but had no GC root.

## Remaining Unknowns

Despite investigation, three questions remain unanswered:

1. **Why does Home Manager generate config files with hardcoded store paths instead of using indirection?**
2. **Can launchd services be granted FDA programmatically?** (Current evidence says no)
3. **Why are .app bundles in `/nix/store` marked with special permissions that require FDA to modify?**

## Recommendations

### Immediate Fixes

1. **Create explicit GC roots** for critical store paths:
   ```bash
   nix-gcroots add ~/.local/state/nix/profiles/home-manager --indirect
   ```

2. **Disable automatic GC** until proper roots are established:
   ```nix
   nix.gc.automatic = false;
   ```

### Long-term Solutions

1. **Use `home-manager.useUserPackages = true`** - Makes Home Manager use system profile paths that are automatically protected

2. **Fix root registration** - Ensure all Home Manager dependencies have proper GC roots

3. **Consider FDA for GC service** - Add `/bin/sh` or create wrapper app with FDA for launchd GC

### For Epic 2 Implementation

1. **Priority 1**: Fix GC root registration for Home Manager store paths
2. **Priority 2**: Investigate using `mkOutOfStoreSymlink` for config files to avoid store path dependencies
3. **Priority 3**: Document FDA requirements for Nix store operations on macOS

## Technical Details

### launchd Service Configuration

- Runs as root in system domain
- Uses `/bin/sh -c` with `/bin/wait4path`
- Minimal PATH environment
- Weekly schedule (Sunday 00:00)

### FDA Impact

Full Disk Access bypasses System Integrity Protection (SIP) restrictions on `/nix/store`. This is a macOS security feature, not a Nix design choice.