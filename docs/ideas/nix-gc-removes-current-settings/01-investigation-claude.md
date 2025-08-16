# Nix Auto-GC Removing User Settings - Investigation

**Date:** 2025-08-10  
**Issue:** Weekly auto-gc appears to cause zsh/p10k settings to disappear

## The Problem

**What happens:**

1. System works perfectly after `nix-rebuild-host`
2. Time passes, everything continues working
3. Weekly GC runs automatically (Sunday midnight via launchd)
4. Next terminal open: p10k asks to configure, settings appear lost
5. Running `nix-rebuild-host` fixes everything

**User's report:** "Nix auto-gc is removing current user settings, particularly prompt settings and possibly other .zsh settings from the config folder"

## Investigation Process

### Phase 1: Initial Wrong Hypothesis

**Previous fix attempt (Commit d1f2e635c - July 28, 2025):**

```nix
# Added to hosts/darwin/shared/default.nix:66
extraOptions = ''
  use-xdg-base-directories = true
'';
# Also extended GC age from 7d to 30d
```

**What the fix intended:** The commit message stated "prevent gc from removing latest home manager generation"

**What we thought it did:** The comment claimed this would help system GC see `~/.local/state/nix/profiles/...` (including HM generations)

**What it ACTUALLY does:**

- Only moves Nix's OWN profiles: `~/.nix-profile` → `~/.local/state/nix/profile`
- Home-manager ALREADY uses `~/.local/state/` independently
- This setting doesn't affect GC's ability to find user profiles at all!

**Discovery:** The previous fix was based on a misunderstanding - `use-xdg-base-directories` only affects where Nix stores its own profiles, NOT whether GC can see user profiles

### Phase 2: Understanding GC Behavior

#### Test 1: System GC dry-run

```bash
sudo nix-collect-garbage --dry-run --delete-older-than 30d --max-freed 8G
```

**Result:**

```text
removing old generations of profile /nix/var/nix/profiles/per-user/root/profile
removing old generations of profile /nix/var/nix/profiles/system
```

**KEY FINDING:** System GC (running as root) NEVER touches user profiles in `~/.local/state/nix/profiles/`!

**Logical problem with this finding:**

- User's settings DO disappear after automatic GC
- So either:
  1. We're wrong about system GC not touching user profiles, OR
  2. The automatic GC service does something different than our manual test
- One of these MUST be true!

#### Test 2: Check user profiles

```bash
ls -la ~/.local/state/nix/profiles/ | grep home-manager | wc -l
# Result: 106 generations!
```

**Initial wrong conclusion:** I suggested the issue was that home-manager activation wasn't working properly.

**User correction:** "WRONG. When we rebuild all works correctly. IT BREAKS WHEN GC comes."

This clarified that:

- `nix-rebuild-host` works perfectly fine
- The problem only appears AFTER garbage collection runs
- Not an activation issue, but a GC-related issue
- Need to double check is it only happens when run on a scheduled or manually as a sudo user as well?

### Phase 3: Testing User GC

**What we did:**

1. Captured a snapshot of the working configuration state (all symlinks in `~/.config/`, current generation numbers, and active store paths) to establish a baseline
2. Ran user GC: `nix-collect-garbage --delete-older-than 30d --max-freed 8G`

**Results:**

```text
removing old generations of profile /Users/happygopher/.local/state/nix/profiles/home-manager
removing old generations of profile /Users/happygopher/.local/state/nix/profiles/profile
finding garbage collector roots...
deleting garbage...
error: chmod "/nix/store/n2nyif07ah4g6zsy3zamnp3pjv7m8gd6-iterm2-3.5.10/Applications/iTerm2.app": Operation not permitted
0 store paths deleted, 0.00 MiB freed
```

**What actually happened:**

- ✅ Generation links 1-99 were removed (only 100-105 remain)
- ❌ Store paths were NOT deleted due to chmod error
- ✅ Terminal still worked perfectly!

**Why the chmod error occurred:**

- macOS .app bundles have special permissions
- Nix store is read-only but GC tries to chmod during cleanup
- This is a KNOWN macOS/nix-darwin issue:
  - NixOS/nix#6765: "[regression] error: chmod operation not permitted"
  - NixOS/nix#8508: "nix-collect-garbage -d does not clean up user profiles in XDG directories when run as root"
  - NixOS/nix#3435: "error: could not set permissions on '/nix/var/nix/profiles/per-user' to 755: Operation not permitted"

**Important discovery about user vs system GC:**

- You're SUPPOSED to run GC as both user AND root!
- User GC cleans: `~/.local/state/nix/profiles/`
- System GC cleans: `/nix/var/nix/profiles/`
- Your `nix-cleanup` alias only does system GC (`sudo -H`), missing user profiles entirely!

**BUT WAIT:** The problem occurs after AUTOMATIC GC (not manual runs)!

- Auto GC runs as root via launchd (confirmed: `org.nixos.nix-gc`)
- We confirmed root GC doesn't touch user profiles
- Yet somehow user store paths ARE getting deleted after auto GC
- This is the core mystery we haven't solved!

**Common workarounds people use:**

1. **Grant Full Disk Access** (from macOS security guides and NixOS/nix#9281 discussions)
   - System Settings → Privacy & Security → Full Disk Access → Add Terminal/iTerm2

2. **Clear file flags** (from StackExchange and NixOS/nix#6765 comments)

   ```bash
   sudo chflags -R nouchg /nix/store/*-vscode-*/
   sudo chflags -R nouchg /nix/store/*-iterm2-*/
   ```

3. **Manual cleanup** (from NixOS wiki "Storage optimization" page)

   ```bash
   # List what would be deleted
   nix-store --gc --print-dead | grep -v -E "(vscode|iterm2)"
   # Delete specific paths
   nix-store --delete /nix/store/[hash]-[package]
   ```

4. **Note:** `--ignore-errors` flag doesn't exist in nix-collect-garbage (I was wrong)

**CRITICAL DISCOVERY:** Our test did NOT reproduce the issue because the chmod error prevented actual store deletion!

### Phase 4: Understanding the Discrepancy

**In our test:**

- chmod error prevented store deletion
- Symlinks remained valid
- No settings were lost

**In production (what actually happens):**

- Weekly GC runs
- Settings disappear (p10k asks to configure)
- `nix-rebuild-host` fixes it

**What we ASSUME but don't know:**

- That store paths get deleted (otherwise why would symlinks break?)
- That symlinks become broken (we never checked this during the actual issue)

**User clarifications:**

- "The permission error doesn't prevent anything" (the issue still happens)
- "I have to rebuild the system (nix-rebuild-host) to fix the configs"

## Current Understanding

### Facts We Know

1. **System setup:**
   - nix-darwin with home-manager as a module
   - Weekly system GC via launchd (Sunday midnight)
   - Started with 106 home-manager generations (now only 7 remain after our test!)
   - No user-level GC automation found

2. **From testing:**
   - System GC doesn't touch user profiles
   - User GC would clean old generations but hit chmod errors
   - chmod errors on macOS .app bundles are a known issue

3. **The real issue:**
   - Something causes store paths to be deleted
   - This breaks symlinks in `~/.config/zsh/`
   - Happens after weekly system GC (correlation)
   - `nix-rebuild-host` always fixes it

### What We Still Don't Know

1. **Why didn't our test reproduce the issue?**
   - chmod error prevented store deletion in test
   - But in production, stores DO get deleted

2. **What actually triggers the store deletion?**
   - Not system GC (doesn't touch user profiles)
   - Not manual user GC (would hit chmod errors)
   - Something else?

3. **Is it specific to AUTOMATIC GC or any system GC?**
   - We only know it happens after weekly auto GC
   - Never tested: Does `sudo nix-collect-garbage --delete-older-than 30d` cause the same issue?
   - Is there something special about launchd context vs manual sudo?

4. **Is there a cascade effect?**
   - Does system GC trigger something else?
   - Is there another cleanup process?
   - Does something run user GC without chmod errors?

## Next Steps

1. **Monitor next real GC event** - What actually happens on Sunday?
2. **Check for other processes** - What else might delete store paths?
3. **Understand chmod context** - Why no error in production?

## Potential Solutions (NOT VALIDATED)

Since we haven't identified root cause, these are speculative:

1. **Disable age-based GC:** Remove `--delete-older-than 30d`
2. **Fix chmod permissions:** Grant Full Disk Access to Terminal/iTerm2
3. **Move mutable state:** Put ZIM in `~/.local/state/zim`
4. **Add user GC:** Properly clean user profiles with error handling

---

**Status:** Investigation incomplete - root cause not identified
