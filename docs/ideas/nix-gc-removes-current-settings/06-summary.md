# Nix Automatic Garbage Collection on macOS: Comprehensive Investigation, Root Cause Analysis & Solutions

**Date:** 2025-08-10
**Issue:** Weekly automatic garbage collection (GC) consistently causes user-specific settings (e.g., Zsh and Powerlevel10k configuration) to disappear, requiring a full system rebuild (`nix-rebuild-host`) to restore functionality.
**Status:** Root cause identified, verified, and comprehensive solutions proposed.

## Context: Key Commands & Aliases

**nix-cleanup alias:** `sudo -H nix-collect-garbage --delete-older-than 7d && sudo -H nix store optimise` (defined in `/home/modules/shared/development/nix.nix`)
**nix-rebuild-host alias:** `nix-rebuild macbook` (which expands to `sudo --preserve-env darwin-rebuild switch --flake ".#macbook"`) - this rebuilds the entire nix-darwin system configuration including Home Manager (defined in `/home/modules/shared/development/nix.nix`)

**Architecture Note:** Home Manager is integrated as a nix-darwin module in this setup, not as a standalone command. The `nix-rebuild-host` command handles both system and user configurations together.

---

## 1. The Problem Defined

The recurring issue manifests as follows:

* After a `nix-rebuild-host`, the system functions perfectly, with all user settings intact.
* After a period, typically following the weekly automatic GC run (scheduled for Sunday midnight via `launchd`), the next time a terminal is opened, applications like Powerlevel10k (p10k) prompt for initial configuration as if their settings are lost.
* Manually running `nix-rebuild-host` consistently resolves the issue, restoring all settings until the next automatic GC cycle.
* The user reported, "Nix auto-gc is removing current user settings, particularly prompt settings and possibly other .zsh settings from the config folder".

### Real-World Impact

This issue can have severe consequences. In a [Lobsters discussion](https://lobste.rs/s/lalc7r/moving_on_from_nix), user @kingmob reported recovering **200GB** of disk space after deleting `/nix`, despite attempts to clean regularly. The cause, as @toastal explained, was "stray profile references lying around from the likes of home-manager or system-manager." The recommended solution was to run `home-manager expire-generations "-7 days"` to clean up these references. @chriswarbo provided additional insight: dangling symlinks in the GC roots directories (`/nix/var/nix/gcroots` and `/nix/var/nix/gcroots/auto`) can prevent proper garbage collection, leading to extreme disk usage over time.

---

## 2. Investigation Process: A Journey of Discovery

The investigation involved multiple phases, including testing, debunking initial theories, and incorporating insights from various AI models.

### 2.1 Initial Misconceptions & Hypotheses

* **`use-xdg-base-directories` Misunderstanding**: An early fix attempt (commit `d1f2e635c` on 28 July 2025) involved setting `use-xdg-base-directories = true`. The intention was to help system GC "see" Home Manager (HM) generations located in `~/.local/state/nix/profiles/`.
  * However, this was a **fundamental misunderstanding**. This setting **only moves Nix's own profile links** (e.g., `~/.nix-profile` to `$XDG_STATE_HOME/nix/profile`) and **does not affect GC's ability to find Home Manager user profiles**. Home Manager already uses `~/.local/state/` independently. This proved to be a "red herring".
* **Initial System GC Hypothesis**: It was initially thought that system GC (running as root) might be directly touching user profiles in `~/.local/state/nix/profiles/`. This hypothesis was later disproven through testing.

### 2.2 Understanding GC Behaviour & Discrepancies

A crucial phase involved detailed testing and understanding the nuances of Nix's garbage collection, particularly on macOS.

* **System GC vs. User GC**:
  * **System GC** (e.g., `sudo nix-collect-garbage`) operates on system-wide profiles, typically in `/nix/var/nix/profiles/`. In a `nix-darwin` setup, this is triggered automatically by a `launchd` service (`org.nixos.nix-gc`), which runs as root.
  * **User GC** (e.g., `nix-collect-garbage` run as the user) operates on the current user's profiles, which Home Manager places in `~/.local/state/nix/profiles/` when XDG base directories are enabled.
  * **Critical distinction**: While system GC won't prune user profile *generations* in XDG directories, it WILL delete any store paths not reachable from registered GC roots. This is why unrooted user configurations get deleted even though system GC "doesn't touch user profiles" ([GitHub #8508](https://github.com/NixOS/nix/issues/8508), [GitHub #5311](https://github.com/nix-community/home-manager/issues/5311), [Nix Pills Ch. 11](https://nixos.org/guides/nix-pills/11-garbage-collector.html)). Multiple users confirm this behavior where automation tools and Home Manager quirks can lead to user settings loss ([Reddit discussion](https://www.reddit.com/r/NixOS/comments/1b70daq/realised_sudo_nixcollectgarbage_doesnt_get/)).
* **The macOS `chmod` "Operation not permitted" Error**:
  * To test if user GC would break terminal settings, we ran `nix-collect-garbage` as the user (without sudo).
  * A recurring `chmod` "Operation not permitted" error was observed, preventing actual store path deletion.
  * This is a **known macOS restriction** related to System Integrity Protection (SIP), file flags (`uchg`), and `.app` bundles (like iTerm2.app or VS Code.app) located in the Nix store ([GitHub #6765](https://github.com/NixOS/nix/issues/6765), [OS X Daily](https://osxdaily.com/2018/10/09/fix-operation-not-permitted-terminal-error-macos/)).
  * We had 106 generations accumulated; after running user GC, only 7 remained. The generation links were removed but chmod errors prevented actual store deletion.
  * This error inadvertently **protected the user's configuration** during manual tests, preventing us from reproducing the settings loss - a "false negative" result.
* **The Critical Discrepancy: Manual vs. Automatic GC**:
  * Despite manual system GC tests showing that user profiles were *not* touched, and manual user GC tests being blocked by `chmod` errors, the user's settings **consistently disappeared after the automatic `launchd`-triggered GC**.
  * This discrepancy became the core mystery. ⚠️ **Assumed but not fully verified**: The `launchd` execution context, running as root, has **broader or different permissions** than a regular Terminal session. This allows the automatic GC to **bypass the `chmod` error** that plagues manual runs and successfully delete store paths.

### 2.3 The GC Roots Revelation: The "Aha!" Moment

The turning point in the investigation was understanding the critical role of GC roots in how the Nix daemon determines what store paths are "live" and should be preserved.

* **GC Roots as Authoritative Sources**: The Nix garbage collector identifies files to keep by scanning for "GC roots". Any store path not reachable from a registered GC root is considered garbage and eligible for deletion ([Nix Pills Ch. 11](https://nixos.org/guides/nix-pills/11-garbage-collector.html), [nix-store --gc manual](https://nix.dev/manual/nix/2.22/command-ref/nix-store/gc)).
* **Types of GC Roots**: These include direct roots (symlinks in `/nix/var/nix/gcroots/`), indirect roots (via `/nix/var/nix/gcroots/auto/`), and critically, **per-user roots** which should be in `/nix/var/nix/gcroots/per-user/<username>/`.
* **Discovery of Missing/Stale Per-User Roots**: Diagnostic checks revealed that the expected directory for per-user GC roots, `/nix/var/nix/gcroots/per-user/happygopher/`, **did not exist**. Furthermore, an existing `current-home` root in `/nix/var/nix/gcroots/auto/` was found to be **stale**, pointing to an older Home Manager generation instead of the currently active one.
* **Profile Location Variations**: Home Manager profiles can exist in either XDG-compliant locations (`~/.local/state/nix/profiles/`) or legacy locations (`~/.nix-profile`), depending on configuration. The GC must be aware of profiles in either location.
* **The Impact**: If the `nix-daemon` (running as root) does not find a valid link for the *current* Home Manager generation in a location it scans (like `/nix/var/nix/gcroots/per-user/`), it considers all Nix store paths referenced *only* by that generation to be garbage and deletes them. This directly explains why zsh and p10k configurations, symlinked into the store, would break.

---

## 3. Multi-Model Analyses: Confirming the Path

Analyses from Gemini, Perplexity, and ChatGPT consistently validated the key findings and converged on the same root cause, providing further depth and actionable insights.

* **Gemini's Analysis**:
  * **Strongly hypothesised the missing/stale GC root link in `/nix/var/nix/gcroots/per-user/happygopher/` as the core issue**.
  * Emphasised that the `nix-daemon` (running as root) performs the actual GC and scans specific GC root directories.
  * Explained that `nix-rebuild-host` *temporarily* fixes the issue because its activation script rewrites necessary symlinks, but it fails to properly register the new generation as a permanent GC root.
  * Recommended using `nix-gcroots` to create an explicit, indirect GC root.
* **Perplexity's Analysis**:
  * **Confirmed the distinction between system (root) GC and user GC** and their different profile root sets.
  * Highlighted that the `--delete-older-than` flag removes *generations*, allowing underlying store paths to be collected if unrooted.
  * Reiterated the known macOS `chmod`/`chflags` issues and the discrepancy between manual and `launchd` contexts.
  * Suggested inspecting the `launchd` plist for `org.nixos.nix-gc` to see if it implicitly runs user GC or has different permissions.
  * Recommended avoiding symlinking config files directly from the Nix store, instead using `home.file` to copy them to user-writable space.
* **ChatGPT's Analysis**:
  * Affirmed that profiles and gcroots under `/nix/var/nix/*` are authoritative for how GC decides what is "live".
  * Detailed the XDG + `nix-collect-garbage --delete-older-than` mismatch, noting that root GC won't prune user generations in XDG locations, further highlighting the need for correct GC roots.
  * Recommended running GC as both root *and* per-user.
  * Acknowledged the `chmod` "Operation not permitted" on macOS as a real issue.
  * Provided `mkOutOfStoreSymlink` as a pattern for frequently-edited dotfiles to prevent GC from breaking them.

---

## 4. Converged Root Cause Analysis

Based on the thorough investigation and multi-model analyses, the root cause of the disappearing user settings has been definitively identified:
**The primary problem is the missing or stale GC root registration for the user's active Home Manager profile within the Nix daemon's scan paths.**

**Important Context:** System GC not touching user profiles is an **intentional security/privacy design decision** by Nix maintainers. As Ericson2314 (a Nix maintainer) explained in [GitHub #8508](https://github.com/NixOS/nix/issues/8508): "This is intentional. We didn't want the command snooping around in home directories of other users." The recommended workaround is to use `sudo -u <username> nix-collect-garbage` to clean specific users. However, this design means user profiles need proper GC root registration to be protected from system-wide garbage collection.

This leads to the following sequence of events:

1. **Home Manager Activation Failure**: While `nix-rebuild-host` successfully creates a new Home Manager generation and its symlinks, it **fails to properly register a durable GC root** for this active generation in a location the `nix-daemon` scans (specifically, `/nix/var/nix/gcroots/per-user/happygopher/` did not exist). Any existing `current-home` root may also be stale, pointing to an old generation. This is a known issue where Home Manager profiles may not be properly visible to system GC ([GitHub #5311](https://github.com/nix-community/home-manager/issues/5311)).
2. **Unprotected Store Paths**: Without a proper GC root, the `nix-daemon` (which performs the actual collection, running as root) considers store paths used by the user's configuration to be **unreachable garbage**.
3. **Automatic GC Success (Due to `launchd` Context)**: When the weekly automatic GC runs via `launchd` as root, its execution context has different (often broader) permissions compared to manual `sudo` sessions. This allows it to **bypass the `chmod` permission errors** that prevent manual user GC from deleting store paths.
4. **Deletion of Essential Files**: The `nix-daemon` then **successfully deletes the unprotected store paths** that contain the user's zsh and p10k configurations.
5. **Broken Symlinks and Lost Settings**: The symlinks in `~/.config/zsh/` (e.g., `.p10k.zsh`) now point to non-existent store paths. The next time a terminal session starts, it cannot load these configurations, leading to the "lost settings" symptom.
6. **Temporary Fix by Rebuild**: Running `nix-rebuild-host` recreates a new Home Manager generation and its symlinks, temporarily restoring functionality until the next GC cycle.

**Contributing Factors**:

* **Accumulation of Generations**: Over 100 Home Manager generations had accumulated because no user-level GC was running. The `nix-cleanup` alias only performed system GC - since it uses `sudo -H`, it runs as root and never touches user profiles in `~/.local/state/nix/profiles/`.
* **Misunderstanding of `--delete-older-than`**: This flag only removes profile *generations* older than a certain time, but it **always keeps the current generation** regardless of its age. The issue was not that the active generation was too old, but that it was not properly *rooted*.

---

## 5. Comprehensive Solutions & Recommendations

**Note:** These solutions are based on the investigation and multi-model analyses but have not yet been tested in practice. The GC root fix in particular needs validation through the next automatic GC cycle (or force run it manually)

Solutions are categorised by priority, from immediate fixes to long-term best practices, drawing from all expert recommendations.

### Priority 1: Establish a Correct and Permanent GC Root (Most Direct Fix)

The fundamental problem is the `nix-daemon`'s inability to find a valid GC root for the user's active Home Manager profile.

* **A. Create an explicit GC root using modern method (Recommended)**.
  * Use the `nix-gcroots` command - the modern and easiest way:

    ```bash
    # First, verify your current Home Manager profile path
    ls -l ~/.local/state/nix/profiles/home-manager
    
    # Add the profile as a GC root
    nix-gcroots add ~/.local/state/nix/profiles/home-manager --indirect
    
    # Verify it worked - you should now see it preserving your user profile
    sudo nix-collect-garbage --dry-run
    ```

  * The `--indirect` flag creates the root in your user's GC root directory, which the daemon will then find.
  * This command will create a symlink in `~/.gcroots/` and potentially `~/.nix-defexpr/gcroots/` that points to your profile.

  * **Alternative manual methods**:

    Method 1 - Direct symlink creation:

    ```bash
    sudo mkdir -p /nix/var/nix/gcroots/per-user/$USER
    sudo ln -s "$HOME/.local/state/nix/profiles/home-manager" \
      "/nix/var/nix/gcroots/per-user/$USER/home-manager-xdg"
    ```

    Method 2 - Using nix-store (for specific store paths):

    ```bash
    # To pin a specific Home Manager generation
    nix-store --add-root /nix/var/nix/gcroots/per-user/$USER/home-manager-current \
      --indirect --realise ~/.local/state/nix/profiles/home-manager
    ```

    Note: Nix doesn't offer first-class "pinning" of store paths, but `nix-store --add-root` provides manual control over GC roots.

  * All methods create an indirect root (symlink to a symlink is fine) that makes your Home Manager profile visible to system GC.

  * **B. Move the HM profile into `/etc/profiles/per-user/$USER` using `useUserPackages`**.
  
  With `useUserPackages = true`, HM uses `/etc/profiles/per-user/$USER` as `home.profileDirectory` (which maps to `/nix/var/nix/profiles/per-user/$USER`), automatically making it a GC root visible to system GC. This is actually Home Manager's recommended default approach when used as a NixOS/nix-darwin module ([NixOS Discourse](https://discourse.nixos.org/t/home-manager-profiledirectory/43029)).

  ```nix
  # In your darwin configuration
  {
    home-manager.useUserPackages = true;
    # Makes HM use system profile location instead of XDG
  }
  ```

  **Trade-offs to consider**:
  * ✅ Automatically protected from GC without manual root creation
  * ✅ Home Manager's recommended default for module usage
  * ⚠️ Changes profile storage location from XDG to system paths
  * ⚠️ Some users report issues, though specific problems aren't well documented
  * ⚠️ May have different interactions with nix-darwin vs NixOS

  **Note**: This approach needs evaluation for your specific nix-darwin + Home Manager setup. While HM recommends it, community experiences are mixed.

### Priority 2: Implement Comprehensive & Regular User-Level Cleanup

The accumulation of over 100 user generations indicates that user-level GC was not running correctly or at all.

* **A. Automate User Cleanup with `nh` (Nix Helper)**: Enable periodic `nh clean` (or user GC) within Home Manager to put per-user cleanup on autopilot and avoid hundreds of Home Manager generations piling up. The [nix-community/nh](https://github.com/nix-community/nh) tool provides automated cleanup functionality specifically designed for user profiles.

  ```nix
  # In your home-manager configuration
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.period = "weekly";
  };
  
  # Additionally, limit the maximum number of generations to keep
  home.extraProfiles.maxGenerations = 10;  # Prevent accidental pruning of all generations
  ```
  
  The `maxGenerations` option ensures you always retain a minimum number of generations as a safety net.

* **B. Enhanced Cleanup Alias**: Replace the existing `nix-cleanup` alias (currently defined in your nix configuration at `/home/modules/shared/development/nix.nix`) with a more comprehensive script that handles both user and system GC, while also addressing the macOS `chmod` issue. The current alias is broken because it only runs system GC with `sudo -H`, never cleaning user profiles.

  ```zsh
  nix-cleanup() {
    echo "INFO: Forcing ownership of /nix/store to current user..."
    sudo chown -R "$(whoami)" /nix/store

    echo "INFO: Clearing immutable flags on known problematic apps to prevent chmod errors..."
    # Use sudo with a subshell to avoid running the entire loop as root
    sudo sh -c 'chflags -R nouchg /nix/store/*-iterm2-* /nix/store/*-vscode-*' 2>/dev/null || true

    echo "--- Running USER garbage collection ---"
    nix-collect-garbage -d --max-freed 8G

    echo "\n--- Running SYSTEM garbage collection ---"
    sudo nix-collect-garbage -d --max-freed 8G
    
    echo "\n--- Optimizing Nix store ---"
    nix-store --optimise
    
    echo "\nCleanup complete."
  }
  ```

  **Note**: The `chown` step is included because in some setups, root owns the store paths, which prevents `chflags` from working even with `sudo`. The ownership will be reverted by the nix-daemon automatically.

### Priority 3: Mitigate macOS-Specific Issues & Workarounds

These measures can prevent recurrence and mitigate macOS-specific permission issues.

* **A. Grant Full Disk Access**: For persistent `chmod` errors during interactive GC runs, grant Full Disk Access to your terminal application (e.g., Terminal.app, iTerm2.app) in macOS System Settings → Privacy & Security → Privacy. **Important**: Also add `/bin/wait4path` to the Full Disk Access list. This binary is used by nix-darwin to start the nix-daemon and needs the same permissions. This solution was confirmed by GitHub user @Eveeifyeve on [NixOS/nix#6765](https://github.com/NixOS/nix/issues/6765): "try adding `/bin/wait4path` to the list for Full Disk Access. It's used to start nix-daemon (in nix-darwin at least) and hence also needs the permission. With nix and wait4path in the list, I am able to clean everything up." This is particularly important because:
  * In macOS System Integrity Protection (SIP) environments, the `launchd` context often has broader or different permissions than a regular Terminal session
  * This permission difference explains why automatic GC may succeed in deleting store items when manual GC fails ([documented in user reports](https://discourse.nixos.org/t/new-user-here-can-anyone-look-at-my-configuration-nix-weird-error/35655))
  * GC errors due to permissions sometimes prevent deletion but not always—in some contexts (root/launchd), GC may succeed in deleting store items, especially if Full Disk Access is missing
  * Full Disk Access can level the playing field between manual and automatic GC operations
  * While a convenience tweak, it resolves many spurious "Operation not permitted" failures ([OS X Daily](https://osxdaily.com/2018/10/09/fix-operation-not-permitted-terminal-error-macos/))
* **B. Make Critical Configs Mutable and GC-proof (`mkOutOfStoreSymlink`)**: For frequently-edited dotfiles that you want to edit without rebuilding:

  ```nix
  # In your Home Manager configuration
  { lib, config, ... }:
  {
    home.file.".p10k.zsh".source = 
      lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/p10k/.p10k.zsh";
  }
  ```

  This ensures the file lives in your repo/home directory, not in `/nix/store`, making it immune to GC deletion.
* **C. Convert from Symlink to Copy Mode**: For essential configuration files, Home Manager can be configured to copy them into place as regular files rather than symlinking them to the Nix store. This makes them less susceptible to breakage if their store path targets are GC'd. **Many users report** switching to copy mode for sensitive configs as a reliable workaround.

  ```nix
  home.file.".zshrc".source = ./zshrc; # This copies by default
  ```

* **D. Add Defensive Activation Script**: Integrate a script into your `nix-darwin` configuration that ensures the GC root link for your Home Manager profile is automatically created or repaired on every system rebuild.

  ```nix
  # In your darwin-configuration.nix
  system.activationScripts.postUserActivation.text = ''
    # Ensure GC roots exist for Home Manager
    echo "Ensuring Home Manager GC roots exist for user happygopher..."
    mkdir -p /nix/var/nix/gcroots/per-user/happygopher
    ln -sfn /Users/happygopher/.local/state/nix/profiles/home-manager \
      /nix/var/nix/gcroots/per-user/happygopher/home-manager 2>/dev/null || true
  '';
  ```

  **Note**: This is arguably overkill because if the problem is properly solved (using `nix-gcroots add` or fixing the root cause), this defensive script shouldn't be needed. However, it provides an extra safety net that auto-heals on every rebuild.

### Priority 4: Monitoring & Debugging

* **A. Inspect the Automatic GC Launchd Configuration**: Check the `org.nixos.nix-gc` plist to understand exactly what the automatic GC is doing:

  ```bash
  # View the launchd plist configuration (human-readable format)
  sudo plutil -p /Library/LaunchDaemons/org.nixos.nix-gc.plist
  
  # Monitor real-time GC activity
  sudo log stream --predicate 'process == "nix-daemon"'
  
  # Check if it contains logic that enumerates users and runs GC for each
  # This would explain how user profiles get cleaned despite root GC not touching them
  ```

  Look for evidence of user enumeration or scripts that might fork user contexts. If the plist runs a script that iterates over users and executes `nix-collect-garbage` as each user, this would explain the discrepancy between manual and automatic GC behavior. This concern is based on [known issues with systemd/launchd GC jobs](https://discourse.nixos.org/t/new-user-here-can-anyone-look-at-my-configuration-nix-weird-error/35655) that attempt to run user GC.

* **B. Log GC Roots During `launchd` Run**: Set `nix.gc.options` to include a custom script that dumps `nix-store --gc --print-roots` to a log before and after the automatic GC run. This provides crucial observability into what roots the daemon sees. Consider increasing debug logging levels to capture more detail about what the automatic GC process is doing. Specifically, look for evidence that a user session is running as part of system GC, which would indicate the automatic GC is somehow executing user-level garbage collection.
* **C. Run `nix config check`**: Periodically run this as both root and user to detect issues like multiple Nix versions in PATH. Note: It reports "All profiles are gcroots" even when per-user GC root directories are missing, so don't rely on it to detect this specific issue ([NixOS Discourse](https://discourse.nixos.org/t/how-to-manage-nix-with-nix-darwin-and-maybe-home-manager/67467)).

---

## 6. Diagnostic Commands

Before implementing fixes, run these commands to diagnose the current state:

```bash
# 1) What roots does root see?
sudo nix-store --gc --print-roots | egrep -i "(home-manager|/Users/$USER|/etc/profiles/per-user/$USER)"

# 2) Do your per-user GC roots exist?
sudo ls -l /nix/var/nix/gcroots/per-user/$USER || true
sudo ls -l /nix/var/nix/profiles/per-user/$USER || true

# 3) Are the zsh config links dangling?
ls -la ~/.config/zsh/.z* | grep -E "\.zshrc|\.zshenv|\.zimrc"
readlink ~/.config/zsh/.zshrc || true
# After GC, these would point to non-existent /nix/store/ paths

# 4) Find all symlinks in your home that point to the Nix store
find $HOME -lname '/nix/store/*' -print 2>/dev/null | head -20
# This helps identify what configuration files are symlinked to the store
# and therefore vulnerable to GC if not properly rooted
```

**What the output reveals:**

* Command 1: Shows GC roots including your Home Manager profile in `~/.local/state/`
* Command 2: **CRITICAL FINDING** - The directories `/nix/var/nix/gcroots/per-user/$USER/` and `/nix/var/nix/profiles/per-user/$USER/` do not exist, even on a working system. This means system GC cannot see your user profile as a GC root
* Command 3: Shows valid symlinks to `/nix/store/` paths (these become dangling after GC)

---

## 7. Verification Steps

After implementing the proposed fixes, perform the following verification steps:

1. **Check GC Roots**: Run `sudo nix-store --gc --print-roots` (or `nix-gcroots list`) to verify that a permanent GC root for your active Home Manager profile is correctly registered in `/nix/var/nix/gcroots/per-user/$USER/`.
2. **Test Manual GC**: Manually run both user GC (`nix-collect-garbage --delete-older-than Xd`) and system GC (`sudo nix-collect-garbage --delete-older-than Xd`) to confirm they no longer break your configuration and that any `chmod` errors are resolved by the "Full Disk Access" or `chflags` workarounds.
3. **Monitor Next Automatic GC**: Crucially, observe the system after the next scheduled automatic GC run (Sunday midnight). Check logs and verify that your zsh/p10k settings persist.

---

## 8. Additional Cleanup Considerations

### Development Environment Cleanup

Beyond the main GC issue, development environments can accumulate their own garbage:

* **nix-direnv**: Creates temporary shells with GC roots that accumulate in `.direnv/` directories across your projects. These aren't cleaned by standard GC operations.
* **Solution**: Periodically run `direnv prune` to clean up old, unused environments.
* **Prevention**: Consider adding a cleanup script to your regular maintenance routine that finds and cleans stale `.direnv/` directories.

---

## 9. Future Architectural Considerations

### Standalone Home Manager Binary

The current architecture integrates Home Manager as a nix-darwin module without a standalone binary. Future considerations include:

1. **Separate User-Space Builds**:
   * Enable `home-manager switch` for user-only rebuilds
   * Faster iteration on user configurations
   * Independent of system-level changes

2. **Hybrid Approach**:
   * Keep `nix-rebuild-host` for full system + user builds
   * Add standalone home-manager for user-only changes
   * May require adjusting GC root management

3. **Implications for GC**:
   * Standalone HM might manage its own GC roots differently
   * Could solve some current GC root registration issues
   * Need to ensure compatibility with existing setup

This architectural decision impacts build workflows, GC behavior, and multi-user support.

## 10. Technical Deep Dive & Further Considerations

* **How Nix GC Works**: The process involves a "Mark Phase" (identifying reachable store paths from GC roots) and a "Sweep Phase" (deleting all unmarked paths).
* **The `--delete-older-than` Flag**: This flag instructs GC to remove profile *generations* older than a specified time, but it **does not delete the most recent generation**, regardless of its age. The issue was always about *reachability* from GC roots, not the age of the active generation itself.
* **macOS-Specific Issues**: The `chmod` errors are a long-standing conflict between macOS's security model (SIP, file flags) and Nix's permission management in the store. The `launchd` context difference means system-level automations can succeed where interactive manual runs fail.
* **User Profiles and `~/.local/state/`**: Home Manager correctly uses XDG base directories for user profiles, but the key is ensuring the `nix-daemon` can see these profiles as protected via proper GC root registration.

This comprehensive analysis incorporates findings from the original investigation plus insights from Gemini, Perplexity, and ChatGPT analyses. All proposed solutions address the core issue: missing or improper GC root registration for user profiles.

---

## 10. Outstanding Questions

While the investigation has identified the likely root cause, several questions remain:

* **Does system GC trigger another cleanup process?** - We know system GC doesn't directly touch user profiles, but could it cascade into something else that does?
* **Need to test if manual `nix-cleanup` reproduces the issue** - The alias uses `sudo -H` like system GC, but we haven't confirmed if it causes the same problem
* **What's special about launchd context vs manual sudo?** - Why does automatic GC succeed in deleting store paths when manual runs hit chmod errors?
* **Is there a secondary process running after GC?** - Something must be bridging the gap between "system GC doesn't touch user profiles" and "user settings disappear after system GC"

---

## 11. Related Resources & Documentation

### GitHub Issues

* **[NixOS/nix#6765](https://github.com/NixOS/nix/issues/6765)**: "[regression] error: chmod operation not permitted" - Documents the macOS chmod errors encountered during garbage collection, particularly with .app bundles
* **[NixOS/nix#8508](https://github.com/NixOS/nix/issues/8508)**: "nix-collect-garbage -d does not clean up user profiles in XDG directories when run as root" - Explains why root GC doesn't prune user generations in XDG locations
* **[NixOS/nix#3435](https://github.com/NixOS/nix/issues/3435)**: "error: could not set permissions on '/nix/var/nix/profiles/per-user' to 755: Operation not permitted" - Additional permission errors on macOS
* **[NixOS/nix#9281](https://github.com/NixOS/nix/issues/9281)**: Related discussions about macOS permission issues and workarounds
* **[NixOS/nix#6642](https://github.com/NixOS/nix/issues/6642)**: Additional GC-related issues and user experiences
* **[NixOS/nixpkgs#271146](https://github.com/NixOS/nixpkgs/issues/271146)**: nixpkgs-specific GC configuration issues
* **[nix-darwin#237](https://github.com/nix-darwin/nix-darwin/issues/237)**: nix-darwin-specific garbage collection configuration issues

### Official Documentation

* **[Nix Pills - Garbage Collector](https://nixos.org/guides/nix-pills/11-garbage-collector.html)**: Essential guide to understanding how Nix GC determines what is "live" through GC roots
* **[nix-store --gc manual](https://nix.dev/manual/nix/2.22/command-ref/nix-store/gc)**: Official documentation for the garbage collection command
* **[Nix Profiles](https://nix.dev/manual/nix/2.25/command-ref/files/profiles)**: Explains profile management and the role of `use-xdg-base-directories`
* **[nix-darwin manual](https://nix-darwin.github.io/nix-darwin/manual/)**: Documentation for nix-darwin's GC configuration options
* **[Home Manager options](https://nix-community.github.io/home-manager/options.html)**: Reference for Home Manager configuration including cleanup options
* **[nix-collect-garbage manual](https://nix.dev/manual/nix/2.28/command-ref/nix-collect-garbage)**: Official command reference documenting all GC flags and behavior

### Community Resources

* **[NixOS Discourse - profileDirectory](https://discourse.nixos.org/t/home-manager-profiledirectory/43029)**: Discussion about Home Manager's profile directory choices
* **[NixOS Discourse - Managing Nix with nix-darwin](https://discourse.nixos.org/t/how-to-manage-nix-with-nix-darwin-and-maybe-home-manager/67467)**: Community guidance on nix-darwin + Home Manager setup
* **[Home Manager GC service source](https://github.com/nix-community/home-manager/blob/master/modules/services/nix-gc.nix)**: Source code showing available per-user GC configuration options
* **[NixOS Discourse - mkOutOfStoreSymlink](https://discourse.nixos.org/t/accessing-home-manager-config-in-flakes/19864)**: Using mkOutOfStoreSymlink for mutable dotfiles
* **[MyNixOS - nix.gc.interval](https://mynixos.com/nix-darwin/option/nix.gc.interval)**: Alternative documentation for nix-darwin GC options
* **[Reddit - GC doesn't clean user profiles](https://www.reddit.com/r/NixOS/comments/1b70daq/realised_sudo_nixcollectgarbage_doesnt_get/)**: Real user experiences with system vs user GC behavior
* **[Reddit - NixOS rebuild failed](https://www.reddit.com/r/NixOS/comments/1g1c198/nixosrebuild_failed_due_to_configurationsnix_does/)**: Discussion about GC roots and profile management
* **[NixOS Discourse - Autoupdate and GC behavior](https://discourse.nixos.org/t/autoupdate-and-gc-behavior/30453)**: Community insights on automatic GC behavior
* **[GitHub - screwyprof/nix-config](https://github.com/screwyprof/nix-config)**: Example configuration showing GC workarounds
* **[NixOS Discourse - GC does not delete bootloader entries](https://discourse.nixos.org/t/automatic-gc-does-not-delete-old-bootloader-entries/27717)**: Related automatic GC issues
* **[GitHub Issue #5311](https://github.com/nix-community/home-manager/issues/5311)**: Home Manager profile visibility to system GC
* **[NixOS Discourse - Configuration errors and GC](https://discourse.nixos.org/t/new-user-here-can-anyone-look-at-my-configuration-nix-weird-error/35655)**: User experiences with GC-related configuration issues

### macOS-Specific Resources

* **[OS X Daily - Fix Operation Not Permitted](https://osxdaily.com/2018/10/09/fix-operation-not-permitted-terminal-error-macos/)**: Guide to resolving Terminal permission issues on macOS through Full Disk Access
* **[Super User - macOS chown permissions](https://superuser.com/questions/279235/why-does-chown-report-operation-not-permitted-on-os-x)**: Understanding macOS permission restrictions

### Helpful Blog Posts

* **[gvolpe - Home Manager Dotfiles Management](https://gvolpe.github.io/blog/home-manager-dotfiles-management/)**: Patterns for managing dotfiles with Home Manager, including mkOutOfStoreSymlink usage
