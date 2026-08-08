{ config, ... }:
{
  # The operator's home INSIDE a cage — one per project. The unix user is `dev`, the person is not.
  #
  # Dotfiles, identity, the VS Code SERVER — and the project's extensions when it is handed some.
  #
  # `projectExtensionsDir` is a STORE PATH, not a module and not a flake ref. That is a trust boundary,
  # not a style choice: devbox builds this home as ROOT (devboxd runs at uid 0, `up.rs:2044`), while a
  # project's own flake is deliberately evaluated unprivileged as `sandbox` because the cage occupant can
  # write it. Taking a module here would put occupant-authored Nix into root's evaluator; taking a path
  # cannot. Whoever passes this must have realised it on the unprivileged side first.
  #
  # `null` — the normal case — places nothing, so every project that declares no extensions keeps sharing
  # ONE generation with all the others.
  #
  # The subdirectory is appended HERE, matching `mkServerExtensions`, so the caller stays free of VS Code's
  # layout. Immutable by construction: one symlink to a store directory that carries its own
  # `extensions.json`. That manifest is load-bearing rather than garnish — the server trusts it OVER the
  # directory and never reconciles it, so per-entry symlinks make a declarative REMOVAL silently fail
  # (measured: dir 7, cache 8, cold server enumerated 8 including the removed one), while replacing the
  # directory and its manifest together means that state cannot arise.
  flake.modules.homeManager.devbox-cage =
    {
      pkgs,
      lib,
      projectExtensionsDir,
      ...
    }:
    let
      # Pinned server + CLI, same expression the node home uses. Placing them is what stops Remote-SSH
      # fetching ~635MB into this cage's `$HOME`, and the wrapper it installs also suppresses the
      # agent-host server. Applied by `nix-rebuild-cage <project>` — nothing triggers it automatically yet.
      r = config.flake.lib.vscodeRemote pkgs;
    in
    {
      # `mkDefault`, so a caller extending this home overrides it. A lambda default (`? null`) does NOT
      # survive home-manager's module wrapping — it falls through to `_module.args` and fails "missing".
      _module.args.projectExtensionsDir = lib.mkDefault null;

      # FAIL CLOSED on anything that is not a store path. Without this the guarantee above is only a
      # comment: a non-store directory that EXISTS is accepted, and nix COPIES it into the store
      # (measured — `/tmp/x` became `…-hm_extensions`). The result is frozen rather than live, so it is
      # not the mutable-drift hazard it looks like; it is a worse one. The copy is made by ROOT's daemon
      # into a world-readable store that is bind-mounted into EVERY cage, so one project's content would
      # be published to all of them. That publication surface was deliberately removed once already
      # (screwyprof/devbox#426) — the same CLASS of hazard, on a different artifact; that issue removed a
      # server-binary dedup pass and deliberately kept extensions with devbox. Nothing should reintroduce
      # the shape.
      #
      # `dirOf == storeDir`, not `hasPrefix storeDir`: the prefix test has no path-separator boundary, so
      # `/nix/store-evil/...` passes it. Measured — that spelling got real content copied into the real
      # store. Requiring exactly one component under the store is what the caller actually hands over.
      assertions = [
        {
          assertion =
            projectExtensionsDir == null || builtins.dirOf (toString projectExtensionsDir) == builtins.storeDir;
          message = ''
            projectExtensionsDir must be a store OUTPUT — exactly one component under
            ${builtins.storeDir} — realised by the caller before it gets here.
            Got: ${toString projectExtensionsDir}
          '';
        }
      ];

      imports = with config.flake.modules.homeManager; [
        happygopher-identity
        dev-direnv # loads the project devshell on cd — why anything else is on PATH
        dev-git
        core-vim
        cli-bat
        cli-eza
        cli-fzf
        cli-zoxide
        cli-zsh
      ];

      # Always `dev` at `/home/dev`, whichever project: identity lives in the bind mounts, not the user.
      home = {
        username = "dev";
        homeDirectory = "/home/dev";
        stateVersion = "24.11";
        # PRECONDITION ON THE CALLER: nothing may already exist at `.vscode-server/extensions`.
        #
        # Every cage that has ever been opened has a REAL DIRECTORY there, placed by devbox.
        # home-manager's `checkLinkTargets` refuses to clobber it and `checkNewGenCollision || exit 1`
        # aborts the whole activation script. It runs `entryBefore [writeBoundary]`, so nothing has been
        # written yet: the home stays pinned on its last successful generation and this — plus every later
        # change — silently stops landing. devbox records the abort as a warning and continues.
        #
        # `force = true`, which `serverFiles` below uses for exactly this class, does NOT help here, and
        # that was measured: its `ln -Tsf` exits 1 with "cannot overwrite directory" on a directory (0 on a
        # file), so forcing just moves the abort into `linkGeneration`.
        #
        # The removal belongs to devbox, which placed it (screwyprof/devbox#481). Not an activation step
        # here: this repo never created that directory. See DECISIONS.md 009 for the measurements.
        file = lib.attrsets.unionOfDisjoint r.serverFiles (
          lib.optionalAttrs (projectExtensionsDir != null) {
            ".vscode-server/extensions".source = "${projectExtensionsDir}/share/vscode/extensions";
          }
        );
      };

      # The cage's login shell is bash and stays that way — devbox's security floor carries no user
      # preferences. So the preference lives here: zsh comes from the user profile and bash execs it for
      # INTERACTIVE shells only, leaving the session rail and `--command` invocations alone.
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
