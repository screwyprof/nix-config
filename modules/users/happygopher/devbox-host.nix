{ config, self, ... }:
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
          config.flake.lib.vscode.mkServerExtensions {
            inherit pkgs;
            exts = b.base ++ b.rust;
          }
        )) r.serverFiles;
      };

      # The rebuild commands, kept out of the general `dev-nix` the Mac also imports. All are NODE
      # commands — a cage has no machinectl to activate itself. The first two must be run from inside
      # this repo; `nix-rebuild-native` builds from `${self}` and needs no particular cwd.
      programs = {
        zsh.initContent = lib.mkAfter ''
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

          # A NATIVE project has no cage to `machinectl shell` into, so activate straight into its home.
          #
          # MANUAL ONLY — never call this from a brokered or automated path. The safety argument is that
          # the operator invokes it deliberately: devbox#395 was rejected precisely because the same
          # operation ran inside brokered `up`, as root, unattended and cage-triggerable. Wiring this
          # into `up` would resurrect that.
          function nix-rebuild-native() {
            local project="$1"
            if [[ -z "$project" ]]; then
              echo "usage: nix-rebuild-native <project>" >&2
              return 2
            fi
            # A NAME, not a path: `devbox sandbox status` accepts both, and a path would build a home at
            # `/work/projects//work/projects/<x>/home`.
            if [[ "$project" == */* ]]; then
              echo "nix-rebuild-native: pass a project NAME, not a path" >&2
              return 2
            fi

            # REFUSE a non-native project. `/work/projects/<p>/home` IS the cage's `$HOME` — the same
            # inode — and a cage already has its own generation owned by the cage principal.
            local st tier home out
            st=$(devbox sandbox status "$project" --json) || {
              echo "nix-rebuild-native: cannot read $project" >&2
              return 1
            }
            tier=$(printf %s "$st" | jq -r .tier)
            if [[ -z "$tier" || "$tier" == "null" ]]; then
              echo "nix-rebuild-native: no tier for $project — is it registered?" >&2
              return 1
            fi
            if [[ "$tier" != "native" ]]; then
              echo "nix-rebuild-native: $project is tier=$tier — refusing," \
                   "that home belongs to the cage" >&2
              return 1
            fi
            # devbox reports where the project actually is. Note this and the generation's baked
            # `homeDirectory` are derived separately, from `.code` and from `$project`; `activate`'s own
            # `checkPathEq HOME` is what catches a mismatch, loudly.
            home="$(dirname "$(printf %s "$st" | jq -r .code)")/home"

            # THE PROJECT'S OWN HOME, not this repo's base. The project declares its extensions and
            # settings in its session flake; this function is the OPERATOR applying them, which is what
            # keeps it out of devbox (devbox#395: devbox must not activate a native home brokered, as
            # root, unattended). Building the base here instead REVERSED every migrated project — the
            # base carries no extensions dir at all.
            #
            # A HELD flake is refused, not applied: the hold marks a flake authored while the project was
            # CAGED, and running it now is the `cage → native` escalation devbox prompts about. Clearing
            # it is `devbox sandbox up`'s job, deliberately, so the operator sees that prompt.
            # FAIL CLOSED on the hold: `jq -r` prints the string `null` for an absent field, so testing
            # `== "true"` would PROCEED against any devbox predating it — and what proceeds is a flake a
            # CAGED agent authored, run at the operator's uid. Require the explicit negative.
            local flake sys ref everr
            flake=$(printf %s "$st" | jq -r .session_flake)
            if [[ "$(printf %s "$st" | jq -r .session_flake_held)" != "false" ]]; then
              echo "nix-rebuild-native: $project's session flake is HELD (or this devbox does not report" \
                   "the hold) — run \`devbox sandbox up $project\` first" >&2
              return 1
            fi

            # The node's operator ref beats the project's pin, exactly as devbox's own `up` does it
            # (devbox#501/#506) — a pin is the project's guess at authoring time, this file is what the
            # node actually runs. ABSENT and UNREADABLE are distinguished: the first is a node that has
            # never had `vm apply --home-flake`, the second is a fault worth naming, and both otherwise
            # look like "silently use whatever rev the project wrote down".
            # FOUR states, not two. `-e` alone is false for a DANGLING symlink, which would report the
            # benign never-applied case for a broken link; and a present-but-EMPTY file reads as success
            # from `cat`, passing no override and saying nothing — which a truncated `vm apply
            # --home-flake` write would make permanent for every project.
            sys="$(uname -m)-linux"
            ref=""
            if [[ -e /var/lib/devbox/operator-profile || -L /var/lib/devbox/operator-profile ]]; then
              ref=$(cat /var/lib/devbox/operator-profile) || {
                echo "nix-rebuild-native: the node's operator ref is unreadable — refusing rather than" \
                     "building $project against its own pin" >&2
                return 1
              }
              if [[ -z "$ref" ]]; then
                echo "nix-rebuild-native: the node's operator ref is EMPTY — refusing rather than" \
                     "building $project against its own pin" >&2
                return 1
              fi
            else
              echo "nix-rebuild-native: no operator ref on this node; $project builds against its own" \
                   "pin" >&2
            fi

            local -a args evalargs
            evalargs=()
            [[ -n "$ref" ]] && evalargs+=(--override-input operator "$ref")
            args=(--no-link --print-out-paths "''${evalargs[@]}")

            # NOTHING BRANCHES ON STDERR. `builtins.trace` writes attacker-chosen lines there during
            # eval, so any decision taken from stderr text is the flake's to make: a home whose value is
            # `trace "error: … does not provide attribute …" (throw …)` talked an earlier version of this
            # function into "declares no home" and installed the base over a project that has one —
            # verbatim the silent downgrade this code exists to prevent. Anchoring the match does not
            # help, because `trace` prefixes only its FIRST line.
            #
            # The question is asked on STDOUT instead, where a trace cannot reach: `x: x ? home` yields a
            # JSON `true`/`false`. `true` covers a home that is present but THROWS — which is right, it
            # declares one and the build reports why it fails.
            #
            # A probe that ERRORS means the flake has no `devbox.<sys>` output at all, or one that throws.
            # Both REFUSE rather than fall back: a session flake registered against this project is a
            # statement that it configures the project, and quietly installing the base instead is the
            # failure mode, not the safe default.
            #
            # `nix build`'s stdout carries the out-paths and nothing else, so `$out` is never parsed out
            # of a merged stream.
            out=""
            local declared=0 probe
            if [[ -n "$flake" && "$flake" != "null" ]]; then
              if probe=$(nix eval --json "''${evalargs[@]}" --apply 'x: x ? home' \
                         -- "$flake#devbox.$sys" 2>/dev/null); then
                case "$probe" in
                  true)  declared=1 ;;
                  false) echo "nix-rebuild-native: $project's flake declares no home — installing the base" >&2 ;;
                  *)     echo "nix-rebuild-native: unreadable probe result '$probe' — refusing" >&2; return 1 ;;
                esac
              else
                nix eval --json "''${evalargs[@]}" --apply 'x: x ? home' -- "$flake#devbox.$sys" >/dev/null
                echo "nix-rebuild-native: $project's flake has no devbox.$sys output, or it does not" \
                     "evaluate — refusing" >&2
                return 1
              fi
              if (( declared )); then
                echo "nix-rebuild-native: building $project's declared home (minutes, first time)" >&2
                # stderr stays on the TERMINAL because this build takes minutes and a captured stream
                # is an unexplained hang. NOT for the reason an earlier version claimed: a flake's
                # `nixConfig` does not PROMPT here — this account is an untrusted nix client
                # (`trusted: false`), so nix warns `ignoring untrusted flake configuration setting` and
                # continues. Measured under a pty.
                out=$(nix build "''${args[@]}" -- "$flake#devbox.$sys.home") || return 1
              fi
            else
              echo "nix-rebuild-native: $project has no session flake registered — installing the base." \
                   "If it has one, register it: devbox sandbox up $project --flake \$(dirname" \
                   "$(printf %s "$st" | jq -r .code))/session" >&2
            fi
            if [[ -z "$out" ]]; then
              out=$(nix build --no-link --print-out-paths --impure \
                    --expr "(builtins.getFlake \"${self}\").lib.nativeProjectHome { project = \"$project\"; }") || return
            fi

            # `activate`, not a hand-rolled placement. A native project runs UNCAGED AS THE OPERATOR, so
            # an agent working there already holds this uid and `wheel` — there is no boundary a
            # placement loop could defend, and home-manager does the job better: `checkLinkTargets`
            # REFUSES to clobber a file the operator owns rather than moving it aside, it installs the
            # profile, keeps generation bookkeeping, and roots the generation itself (a native home is a
            # node-real path, unlike a cage's `/home/dev` — devbox `decisions.md`, verified).
            #
            # RESIDUAL, for a project PROMOTED from cage — its home was occupant-authored. TWO ways that
            # bites, and `activate` stops neither: it runs `nix-env`, which reads nix config from `$HOME`;
            # and it writes THROUGH a symlinked path component. Measured: with `.config` pointing
            # elsewhere, activation populates the target and rc=0, and an existing home-manager link there
            # is replaced with no collision message, because `checkLinkTargets` treats any
            # `-home-manager-files/*` symlink as its own.
            #
            # The shallow check below refuses the realistic plant — a top-level directory the generation
            # writes into. It is deliberately NOT a full-depth walk: that was ~90 lines of this file and
            # four HIGH findings, for a threat that only exists on the promotion path. A promoted home
            # should be reset before its first activate; a never-caged project has no exposure at all,
            # because the agent working there already holds the operator's uid.
            # The guard's own precondition is asserted: `for d in $(cd ... && find ...)` yields an EMPTY
            # list when the `cd` fails, so a bad `$out` disabled the guard instead of erroring. Read with
            # NUL separators, because zsh field-splits on whitespace and a top-level name containing one
            # would otherwise be checked as two wrong paths.
            [[ -d "$out/home-files" ]] || {
              echo "nix-rebuild-native: $out/home-files is missing — refusing" >&2
              return 1
            }
            # A zsh GLOB, not `find`: there is no child whose failure could be swallowed, and a name
            # containing a space or newline cannot split. `(ND/)` is nullglob + dotfiles + directories —
            # dotfiles matter, since every interesting entry here is one.
            local d
            for d in "$out"/home-files/*(ND/); do
              if [[ -L "$home/''${d:t}" ]]; then
                echo "nix-rebuild-native: $home/''${d:t} is a symlink — refusing, reset this home first" >&2
                return 1
              fi
            done

            # M2: re-read the tier AND the hold. The build takes minutes and both guards above are that
            # old by now — and the `up` that promotes cage -> native sets the hold in the SAME act, so
            # re-reading only the tier passes a project whose flake was just marked cage-authored.
            local st2
            st2=$(devbox sandbox status "$project" --json) || {
              echo "nix-rebuild-native: cannot re-read $project after the build — refusing" >&2
              return 1
            }
            if [[ "$(printf %s "$st2" | jq -r .tier)" != "native" ]]; then
              echo "nix-rebuild-native: $project is no longer native — refusing" >&2
              return 1
            fi
            if [[ "$(printf %s "$st2" | jq -r .session_flake_held)" != "false" ]]; then
              echo "nix-rebuild-native: $project's session flake became HELD during the build — refusing" >&2
              return 1
            fi
            # `env -u XDG_*`: home-manager derives the profile and its gcroots from
            # `''${XDG_STATE_HOME:-$HOME/.local/state}`, so with those set the project generation would be
            # installed into the OPERATOR's profile. Unset today, latent tomorrow.
            # `NIX_USER_CONF_FILES=` closes the OTHER promotion-path vector structurally, rather than
            # relying on the operator remembering to reset the home: `activate` runs `nix-env`, which
            # would read `$HOME/.config/nix/nix.conf` — occupant-authored on a promoted home — and
            # `plugin-files` there is dlopen'd before any trust negotiation. Verified: nix tries to load
            # the named plugin without this, and does not with it. Nothing is lost — that file is the
            # PROJECT's, not the operator's, and the system nix.conf and substituters still apply.
            # NO `HOME_MANAGER_BACKUP_EXT`, deliberately, and this is a SECURITY property rather than a
            # preference. Without it a colliding regular file or directory lands in `collisionErrors` and
            # `checkNewGenCollision` exits 1, so `link` never runs. Set it and `link` runs `mv` then
            # `ln -Tsf`, both of which follow a symlinked DIRECTORY COMPONENT — which the depth-1 guard
            # above cannot see. Demonstrated: `.config/nix` pointed at another home renames that home's
            # `nix.conf` aside and replaces it with a generation symlink, at the operator's uid, driven
            # by whoever wrote the project home.
            #
            # NOT "aborts before any write" — measured, that is false and an earlier version of this
            # comment claimed it. `activate` has already run `nix-build`, `nix-env -q` and
            # `nix-store --add-root` by then, creating `.nix-defexpr`, `.nix-profile` and
            # `.local/state/**`, all with `mkdir -p`/`ln` that follow symlinked components. Those paths
            # appear in NO generation's `home-files`, so neither guard can see them. What the variable
            # changes is narrower and still worth having: whether the generation's own files are moved
            # aside and replaced through such a component.
            #
            # The cost is that a home holding a real `.vscode-server/extensions` aborts instead of
            # migrating — loud and recoverable, but home-manager's own abort message recommends
            # `backupFileExtension`, i.e. the thing this deliberately withholds. Remove the directory and
            # re-run. A home already on a managed generation has a symlink there and never collides.
            #
            # `USER` is SET explicitly, not inherited: it is unset in a non-interactive shell and
            # `activate` dies `USER: unbound variable` at its line 54 — so the command would work when
            # typed and fail from a script or an `ssh <host> <cmd>`. `activate` also checks it against
            # the generation's baked username, which is this account.
            env -u XDG_STATE_HOME -u XDG_DATA_HOME -u XDG_CONFIG_HOME -u XDG_CACHE_HOME \
              NIX_USER_CONF_FILES= USER="$(id -un)" \
              HOME="$home" "$out/activate"
          }
        '';

        # Login shell is bash here and in cages; home-manager supplies zsh in the user profile and
        # bash execs it for INTERACTIVE shells only, so scripts and `ssh <host> <cmd>` are unaffected.
        bash = {
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

        home-manager.enable = true;
      };
    };
}
