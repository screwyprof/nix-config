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

      # The rebuild commands, kept out of the general `dev-nix` the Mac also imports.
      #
      # `nix-rebuild-devbox` rebuilds THIS login home and must be run from inside this repo.
      # `nix-rebuild-home` builds from `${self}`, needs no particular cwd, and takes the home to write —
      # so it is the SAME command in every placement, including from inside a cage or a session.
      programs = {
        zsh.initContent = lib.mkAfter ''
          function nix-rebuild-devbox() {
            local out
            out=$(nix build --no-link --print-out-paths ".#homeConfigurations.devbox-host.activationPackage") || return
            "$out/activate"
          }
          # Rebuild the operator's config into a home at an ARBITRARY PATH.
          #
          # TAKES A DIRECTORY, not a project. This repo is the operator's config: it does not know what a
          # "project" is, does not model anyone's directory layout, and no longer shells out to another
          # tool to ask where a home lives. The caller already knows — inside a session it is `$HOME`,
          # from outside you type it — and that is what makes ONE command work in every placement.
          #
          # The old pair took a project NAME and computed `/work/projects/<p>/home`. That path is a
          # consumer's DEFAULT, not a fact: it resolves the root through its own settings chain, so the
          # literal silently went stale the moment that moved. `nix-rebuild-cage` is gone outright —
          # devbox applies the cage config itself on every `up`.
          #
          # MANUAL ONLY, and the reason is measured. `activate` runs `nix-build`, and `$HOME` is a
          # CONFIGURATION INPUT to every nix client it invokes: `plugin-files` is read from
          # `$HOME/.config/nix/nix.conf`, client-side, and `dlopen`ed before any daemon trust
          # negotiation, so `trusted-users` does not contain it (devbox#395). Run it against a home you
          # own. Never wire it into an automated path that could aim it at someone else's ground.
          function nix-rebuild-home() {
            local home="''${1:-$HOME}"
            if [[ "$home" != /* ]]; then
              echo "nix-rebuild-home: pass an ABSOLUTE path (default: \$HOME)" >&2
              return 2
            fi
            if [[ ! -d "$home" ]]; then
              echo "nix-rebuild-home: $home is not a directory" >&2
              return 1
            fi

            # THIS FLAKE as a store path — not a checkout, not the caller's cwd, so there is no writer to
            # guard. Frozen into the shell's function table when the zshrc is sourced, so a change here
            # needs `nix-rebuild-devbox` AND A NEW SHELL before it reaches anywhere.
            local out
            out=$(nix build --no-link --print-out-paths --impure \
                  --expr "(builtins.getFlake \"${self}\").lib.homeAt { homeDirectory = \"$home\"; }") || return

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
