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

        # A NATIVE project has no cage to `machinectl shell` into, so activate straight into its home.
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
          st=$(devbox sandbox status "$project" --json 2>&1) || {
            echo "nix-rebuild-native: $st" >&2
            return 1
          }
          tier=$(printf %s "$st" | jq -r .tier)
          if [[ "$tier" != "native" ]]; then
            echo "nix-rebuild-native: $project is tier=$tier — refusing," \
                 "that home belongs to the cage" >&2
            return 1
          fi
          # ONE source of truth for the location: devbox reports where the project actually is.
          home="$(dirname "$(printf %s "$st" | jq -r .code)")/home"

          # THIS FLAKE as a store path — not a checkout, not the operator's cwd, so there is no writer
          # to guard. The path is frozen into the shell's function table when the zshrc is sourced, so
          # a config change needs `nix-rebuild-devbox` AND A NEW SHELL before it reaches a project home.
          out=$(nix build --no-link --print-out-paths --impure \
                --expr "(builtins.getFlake \"${self}\").lib.nativeProjectHome \"$project\"") || return

          # `activate`, not a hand-rolled placement. A native project runs UNCAGED AS THE OPERATOR, so
          # an agent working there already holds this uid and `wheel` — there is no boundary a
          # placement loop could defend, and home-manager does the job better: `checkLinkTargets`
          # REFUSES to clobber a file the operator owns rather than moving it aside, it installs the
          # profile, keeps generation bookkeeping, and roots the generation itself (a native home is a
          # node-real path, unlike a cage's `/home/dev` — devbox `decisions.md`, verified).
          #
          # RESIDUAL, for a project PROMOTED from cage: that home was occupant-authored, and `activate`
          # runs `nix-env`, which reads nix config from `$HOME`. Review such a home before the first
          # activate. Never-caged projects have no such exposure — the agent there is already you.
          HOME="$home" "$out/activate"
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
