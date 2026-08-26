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
      # OFF for a native PROJECT home (see `flake.lib.nativeProjectHome`). The ORIGINAL reason is
      # gone: devbox owned `.vscode-server/extensions` and swapped the whole directory, so there were
      # two writers — it deleted that machinery (devbox#497) and now reads nothing but
      # `devShells.default` and the optional `devbox.<system>.home`. This file is the only writer.
      # The flag is KEPT deliberately, on its own merits rather than the two-writer one: a native
      # project home is per-project, and injecting the operator's whole catalogue into each is a
      # choice, not a necessity. A module arg rather than an option so this file needs no
      # `options`/`config` split.
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
            # `env -i`, THE SAME ALLOWLIST `nix-rebuild-native` USES, and for the same measured reason:
            # this runs in the operator's interactive shell, which inside a devbox NATIVE session has
            # sourced that project's `<slug>.env` — `nix print-dev-env` output ending in
            # `eval "$shellHook"`. So a project exports a variable and the operator's next rebuild of
            # their OWN LOGIN HOME carries it into activation. `activate` invokes nix clients ~20 times
            # and honours `NIX_STATE_DIR` at its line 53; `NIX_CONFIG` sets `plugin-files`, which those
            # clients `dlopen` before daemon trust negotiation. Same uid, same vector, bigger target.
            #
            # `USER` is part of the allowlist rather than merely passed through: it is unset in a
            # NON-INTERACTIVE shell and `activate` dies `USER: unbound variable` at its line 54, which is
            # exactly where an operator types this — a VS Code terminal on the node inherits sshd's
            # environment, not a login shell's.
            #
            # SAFE FOR THIS HOME, not merely assumed: the login generation's `activate` references an
            # IDENTICAL set of environment variables to a native project's, and adds no activation
            # script of its own, so the allowlist validated there covers this by construction.
            #
            # `nix-rebuild-cage` needs NEITHER guard, and not because its target is the cage's home —
            # because the environment does not cross at all. Measured: `sudo` resets it and
            # `machinectl shell` opens a fresh logind session, so a poisoned `NIX_CONFIG` arrives unset,
            # with `USER=dev` and `HOME=/home/dev` from passwd.
            env -i \
              HOME="$HOME" \
              USER="$(id -un)" \
              TERM="''${TERM:-dumb}" \
              PATH=/run/wrappers/bin:/run/current-system/sw/bin \
              NIX_USER_CONF_FILES= \
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
            # A NAME, not a path — `devbox sandbox status` accepts both, and a path would build a home
            # at `/work/projects//work/projects/<x>/home` — and a CONSERVATIVE one: `$project` is
            # interpolated into a Nix string in the `--expr` fallback below, where `"` and `''${` are
            # live, so the charset is the guard rather than the `/` check alone.
            if [[ "$project" == *[!A-Za-z0-9_.-]* || "$project" != [A-Za-z0-9]* ]]; then
              echo "nix-rebuild-native: '$project' is not a plain project name" >&2
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
            # NO HOLD CHECK. It used to refuse a flake devbox reported as HELD — authored while the
            # project was caged, so running it uncaged was the `cage → native` escalation. devbox
            # ABOLISHED that flow (devbox#550): a caged project cannot become native, so no flake is
            # ever occupant-authored-then-run-as-the-operator, `session_flake_held` is gone from the
            # manifest and from `status --json`, and the guard's own fail-closed shape would now fire
            # on EVERY project — `jq -r` prints `null` for the absent field and `null != "false"`.
            local flake sys ref
            flake=$(printf %s "$st" | jq -r .session_flake)

            # The node's operator ref beats the project's pin, exactly as devbox's own `up` does it
            # (devbox#501/#506) — a pin is the project's guess at authoring time, this file is what the
            # node actually runs. ABSENT and UNREADABLE are distinguished: the first is a node that has
            # never had `vm apply --home-flake`, the second is a fault worth naming, and both otherwise
            # look like "silently use whatever rev the project wrote down".
            # ASK DEVBOX, never read its state file. `/var/lib/devbox/operator-profile` is the LAST
            # FALLBACK of `DEVBOX_HOME`'s resolution chain (env, then build-time baked, then XDG, then
            # the literal) — a default, not a fact. devbox's own `devbox-vm/src/status.rs:20` says as
            # much where it faces the same choice: the ref "lives under the NODE's baked `DEVBOX_HOME`,
            # which a Mac-built binary does not resolve", so it runs the verb instead. Point
            # `DEVBOX_HOME` elsewhere and reading the literal silently yields no ref, which builds every
            # project against its own pin — the failure the override exists to remove.
            #
            # `vm home-flake` is the documented reader, unprivileged (knowing the ref is not a
            # capability, per that same comment), and this function already shells out to `devbox`, so
            # it costs no new dependency. Same defect class as #499: a default written down as a fact.
            #
            # THREE states, and the verb draws them for us: a non-zero exit is a node fault and refuses;
            # `home_flake: null` (or empty) is a node that has never had `vm apply --home-flake`, which
            # says so and proceeds on the project's own pin; a string is the ref.
            sys="$(uname -m)-linux"
            local hf
            hf=$(devbox --json vm home-flake) || {
              echo "nix-rebuild-native: cannot ask devbox for the node's operator ref — refusing rather" \
                   "than building $project against its own pin" >&2
              return 1
            }
            # A message, not a bare `|| return 1` — and NOT because the failure would be silent, which is
            # what an earlier version of this comment claimed. `$(…)` captures STDOUT only, so jq's own
            # `parse error: Invalid numeric literal` reaches the terminal either way; the claim came from
            # a probe whose grep discarded it. What jq cannot say is WHICH of this function's calls
            # failed, or that the verb exiting 0 with unparseable output is a NODE fault rather than the
            # project's. The same is true of the `jq -r .` below, which is left bare deliberately: two
            # shapes, one branded where the attribution is ambiguous.
            ref=$(printf %s "$hf" | jq -r '.home_flake // ""') || {
              echo "nix-rebuild-native: devbox reported an unreadable operator ref — refusing" >&2
              return 1
            }
            if [[ -z "$ref" ]]; then
              echo "nix-rebuild-native: no operator ref on this node; $project builds against its own" \
                   "pin" >&2
            fi

            local -a evalargs
            evalargs=()
            [[ -n "$ref" ]] && evalargs+=(--override-input operator "$ref")

            # ONE RESOLUTION, OF EXACTLY THE PATH THAT GETS BUILT. Nix searches `packages.<sys>.`,
            # `legacyPackages.<sys>.` and then the bare path for EVERY installable, so asking about
            # `#devbox.<sys>` and building `#devbox.<sys>.home` are two searches that a flake can split:
            # `packages.<sys>.devbox.<sys>` shadows the question (no `home` there) while the build falls
            # through to the real one. Reproduced — the project declares a home and the base is installed
            # over it. Naming the full path in both makes that unconstructable: whatever the search
            # resolves, it resolves once and it is what runs.
            #
            # CONSEQUENCE, AND IT IS DELIBERATE: "declares no home" and "declares a broken home" are no
            # longer distinguished, because distinguishing them means reading nix's stderr — which
            # `builtins.trace` writes, so the flake would be choosing its own fate (an earlier version
            # was talked into the base by a forged `does not provide attribute` line). Both REFUSE. A
            # session flake registered against a project is a statement that it configures the project;
            # quietly installing the base instead is the failure mode, not the safe default. The only
            # base fallback left is keyed on the MANIFEST having no session flake at all, which no flake
            # can influence.
            out=""
            local drv errf everr meta
            if [[ -n "$flake" && "$flake" != "null" ]]; then
              errf=$(mktemp) || return 1
              # THE OVERRIDE IS ENFORCED HERE, from `nix flake metadata`'s JSON on STDOUT — a stream the
              # flake cannot write, and one produced WITHOUT evaluating `outputs`, so a hostile
              # `builtins.trace` never runs. `--override-input operator` against a flake that names the
              # input anything else is rc=0 with a warning and NOTHING ELSE, so without this check the
              # project keeps its own pin and the guarantee stated above is decoration. Refuses rather
              # than warns: this is the operator applying their own config, and silently building against
              # a rev they did not choose is the outcome the override exists to prevent.
              #
              # `--override-input` IS PASSED HERE TOO, and not for the override — it implies "do not
              # write a modified lock file". Without it `metadata` RE-LOCKS and writes `flake.lock` into
              # the session dir, which is `root:root` while this runs as the operator: `Permission
              # denied`, empty stdout, and the guard then blamed the flake for lacking an input it
              # visibly declares. Any stale lock did it, including this repo's own documented example.
              #
              # The COMMAND's failure and the ANSWER are separated for the same reason: with both fused,
              # a flake with a syntax error was reported as "declares no input named `operator`".
              if [[ -n "$ref" ]]; then
                if ! meta=$(nix flake metadata --json --override-input operator "$ref" \
                            -- "$flake" 2>|"$errf"); then
                  printf %s\\n "$(<"$errf")" | tr -d '\000-\010\013\014\016-\037' >&2
                  command rm -f "$errf"
                  # Attribution names BOTH inputs, because this call takes two: the flake and the
                  # node's ref. A ref devbox REPORTS but nix cannot resolve fails here rather than at
                  # the read above, and would otherwise be reported as the project's fault. The error
                  # above names which.
                  echo "nix-rebuild-native: could not read $project's flake with the node's operator" \
                       "ref ($ref) — refusing. The error above says which of the two is at fault" >&2
                  return 1
                fi
                if ! printf %s "$meta" | jq -e '.locks.nodes.root.inputs.operator' >/dev/null; then
                  command rm -f "$errf"
                  echo "nix-rebuild-native: $project's flake declares no input named \`operator\`, so the" \
                       "node's config cannot be applied to it — refusing rather than building against the" \
                       "rev the flake pins itself" >&2
                  return 1
                fi
              fi
              # `2>|` overrides this shell's NO_CLOBBER, which is why stderr goes to a file rather than a
              # merged stream. It is DISPLAYED on the error path and never parsed.
              drv=$(nix eval --json "''${evalargs[@]}" --apply 'x: assert (x.type or "") == "derivation"; x.drvPath' \
                    `# A SANITY CHECK, not proof: a flake can set both attrs by hand and forge a path.` \
                    `# What stands behind the result is the store-path shape below, the ^out build, the` \
                    `# home-files assertion, and activate's own checkPathEq HOME.` \
                    -- "$flake#devbox.$sys.home" 2>|"$errf") || drv=""
              everr=$(<"$errf"); command rm -f "$errf"
              # Displayed, never parsed; control characters stripped because the text is the flake's.
              # PRINTING IS NOT ENFORCEMENT — see the metadata check above. An earlier version made this
              # print the only thing standing behind "the node's ref wins", which the flake defeats by
              # burying it: nix emits the override warning at LOCK time, i.e. first, while
              # `builtins.trace` fires at EVAL time, so 400 lines of trace push it off the screen and the
              # last thing the operator reads is flake-authored text that can forge this tool's prefix.
              [[ -n "$everr" ]] && printf %s\\n "$everr" | tr -d '\000-\010\013\014\016-\037' >&2
              if [[ -z "$drv" ]]; then
                echo "nix-rebuild-native: $project's flake does not provide a usable" \
                     "devbox.$sys.home — refusing. Declare one, or clear the registration with an" \
                     "empty --flake on devbox sandbox up $project" >&2
                return 1
              fi
              drv=$(printf %s "$drv" | jq -r .) || return 1
              [[ "$drv" == /nix/store/*.drv ]] || {
                echo "nix-rebuild-native: the home resolved to '$drv', not a derivation — refusing" >&2
                return 1
              }
              echo "nix-rebuild-native: building $project's declared home (minutes, first time)" >&2
              # stderr stays on the TERMINAL because this build takes minutes and a captured stream is an
              # unexplained hang. NOT because of a `nixConfig` prompt, which an earlier version claimed:
              # this account is an untrusted nix client (`trusted: false`), so nix warns `ignoring
              # untrusted flake configuration setting` and continues. Measured under a pty.
              #
              # The DERIVATION is built, not the attribute path — already resolved above, so there is no
              # second search for a flake to steer and no window between deciding and building.
              # `^out`, not `^*`: `*` builds EVERY output and `--print-out-paths` prints one line each,
              # in output-name order, so `$out` became multi-line and failed later with the wrong cause.
              out=$(nix build --no-link --print-out-paths -- "$drv^out") || return 1
            else
              # Computed into a variable first: split across a line continuation, `$(dirname` and its
              # argument become separate echo words and the hint printed a bare `/session`.
              local hint="$(dirname "$(printf %s "$st" | jq -r .code)")/session"
              echo "nix-rebuild-native: $project has no session flake registered — installing the base." \
                   "If it has one, register it: devbox sandbox up $project --flake $hint" >&2
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
            # PREMISE REMOVED (devbox#550) — kept as cheap depth, not as a live defence. It guarded a
            # home PROMOTED from cage, i.e. occupant-authored; promotion is abolished, so a native
            # home has no author but the operator. What follows is therefore belt-and-braces against
            # a hand-made mess, not a threat model. TWO ways the old threat
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
            # The guard's own precondition is asserted: an earlier form iterated `$(cd "$out/…" && find)`,
            # which yields an EMPTY list when the `cd` fails — a bad `$out` disabled the guard rather
            # than erroring.
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
            # `env -u XDG_*`: home-manager derives the profile and its gcroots from
            # `''${XDG_STATE_HOME:-$HOME/.local/state}`, so with those set the project generation would be
            # installed into the OPERATOR's profile. Unset today, latent tomorrow.
            # `NIX_USER_CONF_FILES=`: `activate` runs `nix-env`, which would read
            # `$HOME/.config/nix/nix.conf`, and `plugin-files` there is dlopen'd before any trust
            # negotiation. The THREAT it closed was an occupant-authored home arriving by promotion,
            # which devbox#550 abolished — so this is now hygiene rather than a boundary: that file is
            # the PROJECT's, not the operator's, and reading it during an operator-run activation is
            # still wrong. Verified: nix tries to load the named plugin without this, and does not with
            # it. Nothing is lost — the system nix.conf and substituters still apply.
            # NO `HOME_MANAGER_BACKUP_EXT`, deliberately, and this is a SECURITY property rather than a
            # preference. Without it a colliding regular file or directory lands in `collisionErrors` and
            # `checkNewGenCollision` exits 1, so `link` never runs — BUT ONLY WHERE SOMETHING COLLIDES.
            # Point a depth-2 component at a directory in which the generation's file is ABSENT and
            # `checkLinkTargets` finds nothing to report: `link` runs, and its `mkdir -p` + `ln -Tsf`
            # write through the symlink. Not an escalation — this uid can already write there — but the
            # abort is conditional in a way the rest of this paragraph is not. Set it and `link` runs `mv` then
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
            # `env -i`: an ALLOWLIST, because the previous `-u` list was a blacklist over an environment
            # the attacker chooses, and it lost. This function runs in the operator's interactive shell,
            # which inside a native session has SOURCED that project's `<slug>.env` — `nix print-dev-env`
            # output ending in `eval "$shellHook"` — so a project exports a variable and the operator's
            # next rebuild of ANOTHER project carries it into activation.
            #
            # What the blacklist missed, found by review after five vars had been enumerated: `NIX_CONFIG`
            # sets `plugin-files`, which `activate`'s `nix-env`/`nix-build`/`nix-store` calls `dlopen`
            # BEFORE any daemon trust negotiation — the same vector `NIX_USER_CONF_FILES=` closes for the
            # file, reopened through the variable. Also `NIX_STATE_DIR`, which redirects the profile that
            # `migrateProfile` then `rm`s. And `activate` resolves its own `nix*` binaries from `PATH`.
            # Enumerating the next one is a game with no end; naming what may pass has one.
            #
            # PATH is the system profile explicitly, not the operator's. `activate` uses it only to
            # locate `nix-env`, then REPLACES PATH with a store-only value of its own (its line 7), so no
            # activation hook sees this string at all — an earlier version of this comment claimed hooks
            # would lose `sudo`, which is false for exactly that reason. Wrappers come first anyway,
            # matching the operator's own order: `sw/bin/sudo` is a store symlink and the store cannot
            # carry setuid, so the reverse order shadows the real wrapper. Hygiene, not a fix.
            # TERM only so activation output is readable. NIX_USER_CONF_FILES= must be SET and EMPTY to
            # override the project home's `nix.conf` — an allowlist would otherwise drop it.
            env -i \
              HOME="$home" \
              USER="$(id -un)" \
              TERM="''${TERM:-dumb}" \
              PATH=/run/wrappers/bin:/run/current-system/sw/bin \
              NIX_USER_CONF_FILES= \
              "$out/activate"
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
