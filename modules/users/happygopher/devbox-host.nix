{ config, ... }:
{
  # The operator's home on the devbox NODE — the surface devbox does not manage.
  #
  # No containment here (an extension runs as the operator, with node privileges) and no isolation
  # available: the Remote-SSH server is per host+user, so every folder opened on the node shares one
  # extensions dir. Minimise and declare rather than isolate.
  flake.modules.homeManager.devbox-host =
    { pkgs, lib, ... }:
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
        cli-zoxide
        cli-zsh
      ];

      home = {
        # `happygopher`, not `happygopher.guest` — only the HOME PATH carries lima's suffix, and
        # home-manager validates this against $USER.
        username = "happygopher";
        homeDirectory = "/home/happygopher.guest";
        stateVersion = "24.11";

        # No `go` bundle: Go work happens in cages, which declare it themselves.
        file = lib.attrsets.unionOfDisjoint (config.flake.lib.vscode.mkServerLinks (
          b.base ++ b.rust
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

        # A NATIVE project has no cage to `machinectl shell` into, so its home is PLACED, not activated.
        # STORE PATH, and run from inside this repo, same as the cage function above.
        function nix-rebuild-native() {
          local project="$1"
          if [[ -z "$project" ]]; then
            echo "usage: nix-rebuild-native <project>" >&2
            return 2
          fi

          # REFUSE a non-native project. `/work/projects/<p>/home` IS the cage's `$HOME` — the same
          # inode — and a cage already carries its own home-manager files owned by the cage principal.
          # Placing here would overwrite them with a generation built for the wrong path and uid.
          local tier
          # No `jq`: it is in the cage's `operator-defaults`, not this home, so depending on it here
          # fails closed but uselessly. `tier` is a documented `--json` field, so read it directly.
          tier=$(devbox sandbox status "$project" --json 2>/dev/null \
                 | grep -o '"tier":"[^"]*"' | cut -d'"' -f4)
          if [[ -z "$tier" ]]; then
            echo "nix-rebuild-native: cannot read tier for $project — is it registered?" >&2
            return 1
          fi
          if [[ "$tier" != "native" ]]; then
            echo "nix-rebuild-native: $project is tier=$tier — refusing, this would overwrite a cage's home" >&2
            return 1
          fi

          local out home
          out=$(nix build --no-link --print-out-paths --impure \
                --expr "(builtins.getFlake \"$PWD\").lib.nativeProjectHome \"$project\"") || return
          home="/work/projects/$project/home"

          # ROOT BEFORE PLACING: the symlinks below point into this generation and nothing else roots
          # it — home-manager's own root would live under a `$HOME` we never activate against. The
          # `native-home-` prefix is what devbox's reaper matches (screwyprof/devbox#395); renaming it
          # on either side silently leaks here or orphans the reaper there.
          sudo nix-store --realise --add-root \
            "/nix/var/nix/gcroots/devbox/native-home-$project" "$out" > /dev/null || return

          # PLACE, never `activate`. Activation runs `nix-env`/`nix profile`, and running those with
          # `HOME=<project>/home` reads nix config from an AGENT-WRITABLE directory — `plugin-files` is
          # client-side and dlopen'd before any daemon trust negotiation, so that is a path to code
          # execution as the operator. Symlinking touches no nix client at all.
          local rel
          while IFS= read -r rel; do
            mkdir -p "$home/$(dirname "$rel")"
            ln -sfn "$out/home-files/$rel" "$home/$rel"
          done < <(cd "$out/home-files" && find . \( -type l -o -type f \) | sed 's|^\./||')
          ln -sfn "$out/home-path" "$home/.nix-profile"

          echo "placed $(cd "$out/home-files" && find . \( -type l -o -type f \) | wc -l) files into $home"
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
