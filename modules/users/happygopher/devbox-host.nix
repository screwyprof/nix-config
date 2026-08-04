{ config, ... }:
{
  # The operator's home on the devbox NODE — the surface devbox does not manage.
  #
  # No containment here (an extension runs as the operator, with node privileges) and no isolation
  # available: the Remote-SSH server is per host+user, so every folder opened on the node shares one
  # extensions dir. Minimise and declare rather than isolate.
  flake.modules.homeManager.devbox-host =
    {
      pkgs,
      lib,
      # OFF for a native PROJECT home (see `flake.lib.nativeProjectHome`): there
      # `.vscode-server/extensions` belongs to devbox, which materialises what the project's session
      # flake declares and swaps the WHOLE directory. Two writers on one directory means an `up`
      # erases these links and a rebuild re-injects them. A module arg rather than an option so this
      # file needs no `options`/`config` split.
      placeVscodeExtensions,
      ...
    }:
    let
      b = config.flake.lib.vscode.bundles pkgs;
      # The remote server + CLI, pinned to the same commit this editor negotiates. Placing them is what
      # stops Remote-SSH fetching ~635MB into this home on every fresh connect: both of its install gates
      # are existence checks, and a store symlink satisfies them.
      r = config.flake.lib.vscodeRemote pkgs;
    in
    {
      imports = with config.flake.modules.homeManager; [
        happygopher-identity
        dev-direnv
        dev-git
        # nix LSP + linters; nothing below depends on it.
        dev-nix
        core-vim
        cli-bat
        cli-eza
        cli-fzf
        cli-jq
        cli-zoxide
        cli-zsh
      ];

      # The DEFAULT lives here rather than as a pattern default: the module system resolves a module
      # argument through `_module.args`, so a `? true` in the formals is not consulted.
      _module.args.placeVscodeExtensions = lib.mkDefault true;

      home = {
        # `happygopher`, not `happygopher.guest` — only the HOME PATH carries lima's suffix, and
        # home-manager validates this against $USER.
        username = "happygopher";
        homeDirectory = "/home/happygopher.guest";
        stateVersion = "24.11";

        # No `go` bundle: Go work happens in cages, which declare it themselves.
        # The server+CLI pin is unconditional — that half is the operator's on every home.
        file = lib.attrsets.unionOfDisjoint (lib.optionalAttrs placeVscodeExtensions (
          config.flake.lib.vscode.mkServerLinks (b.base ++ b.rust)
        )) r.serverFiles;
      };

      # Both surfaces' rebuild commands, kept out of the general `dev-nix` the Mac also imports. Both
      # are NODE commands — a cage has no machinectl to activate itself. Run from inside this repo.
      programs.zsh.initContent = lib.mkAfter ''
        function nix-rebuild-devbox() {
          local out
          out=$(nix build --no-link --print-out-paths ".#homeConfigurations.devbox-host.activationPackage") || return
          "$out/activate"
        }

        # STORE PATH, never ./result: a cage binds /nix/store but not this repo.
        function nix-rebuild-cage() {
          local project="$1"
          if [[ -z "$project" ]]; then
            echo "usage: nix-rebuild-cage <project>" >&2
            return 2
          fi
          local out
          out=$(nix build --no-link --print-out-paths ".#homeConfigurations.devbox-cage.activationPackage") || return

          # ROOT IT FROM THE NODE, before activating. home-manager roots its own generation at
          # `$HOME/.local/state/nix/...` — but a cage's `$HOME` is `/home/dev`, which does NOT exist on the
          # node, so nix drops those roots as stale links and the generation is unrooted from the only
          # place GC actually runs. Everything the cage home points at (the placed VS Code server and CLI
          # live *inside* the generation's `home-manager-files`) would then be collected by the next
          # `nix-collect-garbage`, leaving dangling symlinks and a ~635MB re-download per cage. Observed:
          # an activation package built minutes earlier was collected mid-session.
          #
          # NAME CONTRACT — `cage-home-<slug>` is agreed with devbox and must not be renamed on one side
          # alone. It deliberately avoids `-vscode-server-`, the infix devbox's gcroot reaper matches on
          # (`prune.rs` `gather_vscode_roots`), so this root is invisible to that sweep — which is also why
          # nothing reaps it today. devbox screwyprof/devbox#355 adds `cage-home-` to the same reaper that
          # already handles `extensions-<slug>`, so a `devbox rm` stops leaving the generation pinned.
          # Renaming this prefix here silently orphans that reaper; renaming it there silently leaks.
          sudo nix-store --realise --add-root "/nix/var/nix/gcroots/devbox/cage-home-$project" "$out" > /dev/null || return

          sudo machinectl shell "dev@$project" /run/current-system/sw/bin/bash -lc "$out/activate"
        }

        # $3 = "check" to validate without creating: the CLEANUP caller must not materialise
        # directories from the OLD generation — a fresh home would end up with an empty
        # `.vscode-server/extensions`, which the native generation deliberately disowns to devbox.
        _devbox_native_walk() {
          local dir="$2" cur="$1" mode="$3" part
          [[ "$dir" == "." ]] && return 0
          while IFS= read -r part; do
            [[ -z "$part" ]] && continue
            cur="$cur/$part"
            if [[ -L "$cur" ]]; then
              [[ "$mode" == "check" ]] \
                && echo "nix-rebuild-native: skipping $cur — symlinked component" >&2 \
                || echo "nix-rebuild-native: $cur is a symlink — refusing to place through it" >&2
              return 1
            fi
            if [[ ! -d "$cur" ]]; then
              [[ "$mode" == "check" ]] && return 1
              mkdir "$cur" || return 1
            fi
          done < <(printf '%s\n' "$dir" | tr '/' '\n')
        }

        # The `|| return 1`s guard each STEP; this guards the ENUMERATION. A failed `cd` left the
        # loop body unexecuted and the function reported success having placed nothing — after
        # pointing `.nix-profile` at a path that did not exist.
        [[ -d "$out/home-files" ]] || {
          echo "nix-rebuild-native: $out/home-files is missing" >&2
          return 1
        }

        # A NATIVE project has no cage to `machinectl shell` into, so its home is PLACED, not
        # activated. STORE PATH, and run from inside this repo, same as the cage function above.
        function nix-rebuild-native() {
          local project="$1"
          if [[ -z "$project" ]]; then
            echo "usage: nix-rebuild-native <project>" >&2
            return 2
          fi
          # A NAME, not a path: `devbox sandbox status` accepts both, and a path would pass the tier
          # guard and then build a home at `/work/projects//work/projects/<x>/home`.
          if [[ "$project" == */* ]]; then
            echo "nix-rebuild-native: pass a project NAME, not a path" >&2
            return 2
          fi

          # REFUSE a non-native project. `/work/projects/<p>/home` IS the cage's `$HOME` — the same
          # inode — and a cage already carries its own home-manager files owned by the cage principal.
          # Placing here would overwrite them with a generation built for the wrong path and uid.
          # NOT `status`: that is a zsh special parameter (a synonym for `?`) and assigning to it
          # fails read-only, which killed this function outright — invisible when testing under bash.
          local st tier home
          st=$(devbox sandbox status "$project" --json 2>&1) || {
            echo "nix-rebuild-native: $st" >&2
            return 1
          }
          tier=$(printf %s "$st" | jq -r .tier)
          if [[ "$tier" != "native" ]]; then
            echo "nix-rebuild-native: $project is tier=$tier — refusing," \
                 "this would overwrite a cage's home" >&2
            return 1
          fi
          # ONE source of truth for the location: devbox reports where the project actually is, so a
          # slug that does not match its directory cannot send the placement somewhere else.
          home="$(dirname "$(printf %s "$st" | jq -r .code)")/home"

          # RESIDUAL, and it is not closed by the pin: this repo is itself a devbox CAGE project, so
          # its occupant owns the tree (`sandbox:sandbox`) and `git+file://` reads the DIRTY worktree —
          # no commit needed. An occupant who edits it gets their `home.file` placed into a native
          # home and executed as the operator on the next session. The pin narrows WHO can do it from
          # "any project's occupant, if the operator's cwd is in their tree" to "the nix-config
          # occupant, always"; it does not remove it. `nix-rebuild-devbox` above has the same exposure
          # and additionally runs `activate`, so this is a class the whole file shares.
          #
          # Closing it means taking the flake from somewhere the occupant cannot write — a
          # `github:owner/repo/<rev>` ref, or an operator-owned checkout outside `/work/projects`.
          # That is a layout decision, not something this function can do.
          #
          # PINNED, not cwd-derived. `git rev-parse --show-toplevel` resolves against wherever the
          # operator happens to be, and every `/work/projects/*/code` is an agent-writable git repo —
          # so running this from inside one would evaluate THAT project's flake, build it as the
          # operator, pin it with `sudo`, and symlink its `home-files` (`.zshenv`, `.bashrc`, …) into
          # a home. Proven end to end by review. The comment "run from inside this repo" was not a
          # control.
          #
          # `git+file://`, not a bare path: a path flakeref copies the whole worktree (including
          # `.git`) into the store and re-hashes on every git operation.
          local out root old repo
          repo=/work/projects/nix-config/code
          if [[ "$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null)" != "$repo" ]]; then
            echo "nix-rebuild-native: $repo is not a git worktree — clone screwyprof/nix-config there" >&2
            return 1
          fi
          out=$(nix build --no-link --print-out-paths --impure \
                --expr "(builtins.getFlake \"git+file://$repo\")\
                        .lib.nativeProjectHome \"$project\"") || return
          root="/nix/var/nix/gcroots/devbox/native-home-$project"
          # Existence, not just the string: `readlink -f` on a path whose parent exists but whose final
          # component does not PRINTS the path and exits 0. Since the root is created a few lines down,
          # a later `-d "$old/home-files"` would then resolve through the NEW root and report a stale
          # sweep that never happened.
          old=
          [[ -L "$root" ]] && old=$(readlink -f "$root" 2>/dev/null)

          # A failure PART WAY through leaves a half-placed home with the root already moved: the
          # previous generation is unrooted while some of its links remain. Root-before-place is still
          # right — the alternative is placing links nothing roots.
          #
          # ROOT BEFORE PLACING: the symlinks below point into this generation and nothing else roots
          # it — home-manager's own root would live under a `$HOME` we never activate against. The
          # `native-home-` prefix is a name contract with devbox's reaper; renaming it on one side
          # leaks here or orphans the reaper there.
          sudo nix-store --realise --add-root "$root" "$out" > /dev/null || return

          # RE-READ the tier: the build can take minutes, and the operator may have re-tiered in
          # between. Cheap, and the whole guard is about not writing into a cage's home.
          if [[ "$(devbox sandbox status "$project" --json 2>/dev/null | jq -r .tier)" != "native" ]]; then
            echo "nix-rebuild-native: $project is no longer native — refusing" >&2
            # Do not leave the root pinning a generation for a project that is not native any more.
            # Cost: any links already in that home now point at an unrooted path and dangle at the
            # next GC — acceptable, since the home is no longer one this function maintains.
            sudo rm -f "$root"
            return 1
          fi

          # PLACE, never `activate`. Activation runs `nix-env`/`nix profile`, and running those with
          # `HOME=<project>/home` reads nix config from an AGENT-WRITABLE directory — `plugin-files`
          # is client-side and dlopen'd before any daemon trust negotiation, so that is a path to code
          # execution as the operator. Symlinking touches no nix client at all.
          # NO SYMLINKED COMPONENT, anywhere. `mkdir -p` and `ln` resolve INTERMEDIATE components, and
          # this home was the cage's `$HOME` — occupant-owned. A promotion preserves a planted symlink
          # (devbox's chown is `AT_SYMLINK_NOFOLLOW` by design), so `~/.config -> <operator home>/.config`
          # planted while caged would send these operator-privileged writes outside the project. devbox
          # solved the same problem for `.vscode-server` with `openat`/`O_NOFOLLOW`; shell cannot, so
          # walk and refuse. Reproduced before fixing.
          if [[ -L "$home" || ! -d "$home" ]]; then
            echo "nix-rebuild-native: $home is missing or a symlink — refusing" >&2
            return 1
          fi
          # Walk EVERY component and refuse a symlinked one. Shared by both loops: the cleanup loop
          # takes its rels from the OLD generation and is just as able to write outside the home.
          # `printf '%s\n'`, not `%s`: an unterminated last line makes `read` return non-zero on the
          # final component, so it is never checked and never created — which is exactly the component
          # an occupant plants, and left the escape open after the first fix.
          local rel target t placed=0 removed=0
          while IFS= read -r -d ''' rel; do
            target="$home/$rel"
            _devbox_native_walk "$home" "$(dirname "$rel")" || return 1
            # `-T`, never `-n`: with `-n` a target that is a REAL directory makes `ln` link INSIDE it
            # and exit 0 — silently skipping the ~635MB server pin on any home VS Code has opened.
            if [[ -e "$target" && ! -L "$target" ]]; then
              # Not ours. A directory is what the editor recreates, so replace it — home-manager marks
              # the two server/CLI entries `force` for that reason, though this branch is broader than
              # those two. A regular file may be the operator's, so keep a copy. home-manager's own
              # `checkLinkTargets` would ABORT here instead; this is deliberately more permissive.
              if [[ -d "$target" ]]; then rm -rf "$target" || return 1
              # `-T`: `mv` follows a SYMLINKED destination, so a planted `<file>.hm-backup -> <dir>`
              # moves the file there. Same class as the `ln -n` → `ln -T` fix below.
              elif [[ -e "$target.hm-backup" ]]; then
                echo "nix-rebuild-native: $target.hm-backup exists — refusing" >&2
                return 1
              else mv -Tf "$target" "$target.hm-backup" || return 1
              fi
            fi
            ln -Tsf "$out/home-files/$rel" "$target" || return 1
            placed=$((placed + 1))
          done < <(cd "$out/home-files" && find . \( -type l -o -type f \) -printf '%P\0')
          (( placed > 0 )) || {
            echo "nix-rebuild-native: placed nothing — refusing to report success" >&2
            return 1
          }

          # Through the same real-target handling as the loop: `ln -T` refuses to overwrite a real
          # DIRECTORY, which would otherwise fail here after every link was already placed.
          target="$home/.nix-profile"
          if [[ -e "$target" && ! -L "$target" ]]; then
            if [[ -d "$target" ]]; then
              rm -rf "$target" || return 1
            elif [[ -e "$target.hm-backup" ]]; then
              echo "nix-rebuild-native: $target.hm-backup exists — refusing to clobber it" >&2
              return 1
            else
              mv -Tf "$target" "$target.hm-backup" || return 1
            fi
          fi
          # This makes PATH and `hm-session-vars.sh` resolve, at the cost of `nix profile` in that home:
          # the target is a plain store path with no `manifest.json`. The occupant here IS the operator,
          # so that is a real if minor loss.
          ln -Tsf "$out/home-path" "$target" || return 1

          # What the PREVIOUS generation placed and this one does not: without this the link survives,
          # the gcroot has moved on, and the next GC leaves it dangling — which the editor's
          # existence-check install gate happily accepts.
          local had_previous=
          [[ -d "$old/home-files" ]] && had_previous=1
          if [[ -n "$had_previous" ]]; then
            while IFS= read -r -d ''' rel; do
              [[ -e "$out/home-files/$rel" ]] && continue
              _devbox_native_walk "$home" "$(dirname "$rel")" check || continue
              target="$home/$rel"
              t=$(readlink "$target" 2>/dev/null)
              if [[ -L "$target" && "$t" == /nix/store/*-home-manager-generation/home-files/* ]]; then
                rm -f "$target" && removed=$((removed + 1))
              fi
            done < <(cd "$old/home-files" && find . \( -type l -o -type f \) -printf '%P\0')
          fi

          if [[ -n "$had_previous" ]]; then
            echo "placed $placed (+ .nix-profile), removed $removed stale, into $home"
          else
            echo "placed $placed (+ .nix-profile), no previous generation, into $home"
          fi
        }
      '';

      # Login shell is bash here and in cages; home-manager supplies zsh in the user profile and bash
      # execs it for INTERACTIVE shells only, so scripts and `ssh <host> <cmd>` are unaffected.
      programs.bash = {
        enable = true;
        # bash only springboards to zsh (initExtra below), so completion is never used — and the
        # default sources it unguarded, which errors on nixpkgs' minimal bash.
        enableCompletion = false;
        initExtra = ''
          if [[ $- == *i* ]] && [[ -z "$ZSH_VERSION" ]] && command -v zsh > /dev/null; then
            exec zsh -l
          fi
        '';
      };

      programs.home-manager.enable = true;
    };
}
