# Nix Auto-GC Removing User Settings - ChatGPT Analysis

Alright, I dug into what you wrote and cross-checked the tricky bits against docs/issues. Here’s where your write-up is spot-on, where it needs tightening, and the most likely fixes.

---

## What your notes get right (and what to tweak)

* **`use-xdg-base-directories` misunderstanding — you’re right to call that out.**
  That setting only moves *Nix’s* profile links (e.g. `~/.nix-profile` → `$XDG_STATE_HOME/nix/profile`). It doesn’t, by itself, make GC “see” Home-Manager (HM) generations. It also changes how `nix-collect-garbage --delete-older-than` prunes profiles (see below). ([nix.dev](https://nix.dev/manual/nix/2.25/command-ref/files/profiles?utm_source=chatgpt.com))

* **Root GC schedule on macOS (nix-darwin) is a LaunchDaemon.**
  `nix.gc.automatic`, `nix.gc.interval`, and `nix.gc.options` are the knobs. Default is a weekly Sunday run; you can change the time and flags. ([nix-darwin.github.io](https://nix-darwin.github.io/nix-darwin/manual/?utm_source=chatgpt.com), [MyNixOS](https://mynixos.com/nix-darwin/option/nix.gc.interval))

* **Root GC vs user profiles (XDG).**
  Your “system GC never touches user profiles in `~/.local/state/nix/profiles`” is *half true*:
  *Root GC’s “delete old generations” step* doesn’t prune XDG user generations (known gap) — hence the pile-up you saw. But *the actual `nix-store --gc` phase* will still delete any store paths that are not reachable from **registered GC roots**. If your active HM profile isn’t registered as a GC root under `/nix/var/nix/gcroots` or `/nix/var/nix/profiles`, root GC can collect its files, which would break your zsh/p10k links. ([GitHub](https://github.com/NixOS/nix/issues/8508?utm_source=chatgpt.com), [nixos.org](https://nixos.org/guides/nix-pills/11-garbage-collector.html?utm_source=chatgpt.com))

* **The chmod “Operation not permitted” on macOS during GC is a real thing.**
  It’s a known macOS restriction (TCC / file flags / SIP) that frequently shows up with `.app` bundles. People work around it by granting Terminal/iTerm *Full Disk Access* or clearing flags; but this is separate from the root cause of your p10k reset. ([GitHub](https://github.com/NixOS/nix/issues/6765?utm_source=chatgpt.com), [OS X Daily](https://osxdaily.com/2018/10/09/fix-operation-not-permitted-terminal-error-macos/?utm_source=chatgpt.com), [Super User](https://superuser.com/questions/279235/why-does-chown-report-operation-not-permitted-on-os-x?utm_source=chatgpt.com))

* **Running GC as both root *and* per-user is recommended.**
  nix-darwin can schedule the system GC; Home-Manager can schedule a *user* GC (or `nh clean`) so your user generations get pruned too. ([nix-darwin.github.io](https://nix-darwin.github.io/nix-darwin/manual/?utm_source=chatgpt.com), [nix-community.github.io](https://nix-community.github.io/home-manager/options.html?utm_source=chatgpt.com))

---

## The most likely root cause

After the weekly **root** GC runs, some HM-managed files under `~/.config/zsh` (e.g. `.p10k.zsh`) end up pointing at store paths that were collected. Why? Because the **active HM profile is not visible as a GC root** to the root GC.

That can happen when:

1. Your HM profile lives only under XDG (`~/.local/state/nix/profiles/home-manager`) **and**
2. There is **no** corresponding per-user root under `/nix/var/nix/gcroots/per-user/$USER/…` **or** `/nix/var/nix/profiles/per-user/$USER/…`.

In that situation, root GC won’t see your current HM generation as a root and can delete its files, leaving your zsh symlinks dangling. The p10k wizard then pops up because it can’t load the config. (This lines up with the fact that a fresh `nix-rebuild-host` always fixes it — you get a new generation and new links.)

Background reading on how GC decides what is “live”: profiles and gcroots under `/nix/var/nix/*` are authoritative. ([nixos.org](https://nixos.org/guides/nix-pills/11-garbage-collector.html?utm_source=chatgpt.com))
And the “XDG + nix-collect-garbage --delete-older-than” mismatch is a known issue: root GC won’t prune user generations in XDG locations. ([GitHub](https://github.com/NixOS/nix/issues/8508?utm_source=chatgpt.com))

---

## Quick fact-check tasks (do these once)

Run these right after a good rebuild **and** again immediately after an automatic GC event:

```bash
# 1) What roots does root see?
sudo nix-store --gc --print-roots | egrep -i "(home-manager|/Users/$USER|/etc/profiles/per-user/$USER)"

# 2) Do your per-user GC roots exist?
sudo ls -l /nix/var/nix/gcroots/per-user/$USER || true
sudo ls -l /nix/var/nix/profiles/per-user/$USER || true

# 3) Are the zsh links dangling?
ls -l ~/.p10k.zsh ~/.config/zsh 2>/dev/null | sed -n '1,200p'
readlink ~/.p10k.zsh || true
```

**What you should see:** at least one root pointing to your HM profile (either via `/nix/var/nix/gcroots/per-user/$USER/...` or `/nix/var/nix/profiles/per-user/$USER/home-manager`). If nothing turns up, that’s the smoking gun. For reference on GC roots behavior, see Nix Pills and the `nix-store --gc` manual. ([nixos.org](https://nixos.org/guides/nix-pills/11-garbage-collector.html?utm_source=chatgpt.com), [nix.dev](https://nix.dev/manual/nix/2.22/command-ref/nix-store/gc?utm_source=chatgpt.com))

---

## Solid fixes (pick one of A/B, then consider C/D)

## A) Ensure a permanent GC root for your HM profile (most direct)

Create an explicit gcroot that points to your *current* HM profile link:

```bash
sudo mkdir -p /nix/var/nix/gcroots/per-user/$USER
sudo ln -s "$HOME/.local/state/nix/profiles/home-manager" \
  "/nix/var/nix/gcroots/per-user/$USER/home-manager-xdg"
```

This is an **indirect GC root** (a symlink to a symlink is fine), and it makes root GC preserve the active HM generation. ([nixos.org](https://nixos.org/guides/nix-pills/11-garbage-collector.html?utm_source=chatgpt.com))

## B) Move the HM profile into `/etc/profiles/per-user/$USER` (so root GC always sees it)

When HM is used as a nix-darwin module, you can have it use the system’s per-user profiles tree instead of the XDG path:

```nix
# in your darwin configuration
{
  home-manager.useUserPackages = true;
  # (keep your existing HM module setup)
}
```

With `useUserPackages = true`, HM picks `/etc/profiles/per-user/$USER` as `home.profileDirectory` (which maps into `/nix/var/nix/profiles/per-user/$USER`), and that directory is treated as a GC root by Nix. This makes the active HM generation visible to root GC. ([NixOS Discourse](https://discourse.nixos.org/t/home-manager-profiledirectory/43029?utm_source=chatgpt.com), [nixos.org](https://nixos.org/guides/nix-pills/11-garbage-collector.html?utm_source=chatgpt.com))

> Tip: after changing this, rebuild and confirm `ls -l /nix/var/nix/profiles/per-user/$USER` shows `home-manager`/`profile` symlinks owned correctly.

## C) Schedule a *user* cleanup too (so generations don't pile up)

Let root do the store GC, and let your user prune old generations. With Home-Manager you can enable periodic `nh clean` (or user GC):

```nix
# Home-Manager
{
  programs.nh.enable = true;
  programs.nh.clean.enable = true;
  # e.g. weekly; adjust to your taste
  programs.nh.clean.period = "weekly";
  # keep last 5 generations, or use --older-than
  programs.nh.clean.extraArgs = [ "--keep 5" ];
}
```

This puts the per-user cleanup on autopilot and avoids hundreds of HM generations. (Option names can vary slightly by HM release; see HM options & the `nh` module.) ([nix-community.github.io](https://nix-community.github.io/home-manager/options.html?utm_source=chatgpt.com), [GitHub](https://github.com/nix-community/home-manager/blob/master/modules/programs/nh.nix?utm_source=chatgpt.com))

## D) Make p10k (and other frequently-edited dotfiles) **mutable** and GC-proof

If you want zero chance that GC breaks your prompt (and you like editing `.p10k.zsh` without rebuilding), don’t serve it from the store. Use `mkOutOfStoreSymlink`:

```nix
# Home-Manager
{ lib, ... }:
{
  home.file.".p10k.zsh".source =
    lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/p10k/.p10k.zsh";
}
```

That file will live in your repo/home, not in `/nix/store`, so GC can’t remove it. This pattern is common for fast-iterated configs (Neovim, shells, etc.). ([NixOS Discourse](https://discourse.nixos.org/t/accessing-home-manager-config-in-flakes/19864?utm_source=chatgpt.com), [gvolpe.github.io](https://gvolpe.github.io/blog/home-manager-dotfiles-management/?utm_source=chatgpt.com))

---

## "Why did our manual test not reproduce the break?"

Likely because your user-GC run hit the macOS chmod/TCC error before it actually deleted anything in the store — so your HM symlinks stayed valid. The automatic *root* GC doesn’t hit that particular terminal permission issue and proceeds to delete dead paths, exposing the missing gcroot for the active HM profile. The chmod issue is documented; the GC roots behavior is how Nix works. ([GitHub](https://github.com/NixOS/nix/issues/6765?utm_source=chatgpt.com), [nixos.org](https://nixos.org/guides/nix-pills/11-garbage-collector.html?utm_source=chatgpt.com))

---

## Nice-to-haves for observability

* **Log what roots GC sees during the LaunchDaemon run.**
  Set `nix.gc.options = "--delete-older-than +5";` (for example) and wrap the service with a small script that dumps `nix-store --gc --print-roots` to a log before and after. (nix-darwin exposes the LaunchDaemon; see `nix.gc.*` options.) ([nix-darwin.github.io](https://nix-darwin.github.io/nix-darwin/manual/?utm_source=chatgpt.com))

* **Run `nix config check` as root and as your user.**
  It will complain if profiles aren’t gcroots or if multiple Nix versions are on `PATH`. You want “All profiles are gcroots.” (In newer Nix this is the `nix config check` output.) ([NixOS Discourse](https://discourse.nixos.org/t/how-to-manage-nix-with-nix-darwin-and-maybe-home-manager/67467?utm_source=chatgpt.com))

* **If you’re still seeing chmod errors in interactive runs**, grant Full Disk Access to Terminal/iTerm in macOS Privacy, which suppresses many of the spurious “Operation not permitted” failures. (This is a convenience tweak; it doesn’t fix the gcroot issue.) ([OS X Daily](https://osxdaily.com/2018/10/09/fix-operation-not-permitted-terminal-error-macos/?utm_source=chatgpt.com))

---

## TL;DR fix order I’d try

1. **Create the explicit gcroot** (A) right now and confirm the next auto-GC doesn’t nuke the prompt.
2. **Or** flip to **`home-manager.useUserPackages = true;`** (B) so HM lives under `/etc/profiles/per-user/$USER`.
3. Add **per-user cleanup** via HM/`nh` (C).
4. For p10k (and similar), consider **`mkOutOfStoreSymlink`** (D) so your prompt is never dependent on the store.

If you want, paste your `darwin`+HM snippets (especially anything around `nix.gc.*`, `home-manager.useUserPackages`, and zsh/p10k declarations) and I’ll sanity-check them against this.
