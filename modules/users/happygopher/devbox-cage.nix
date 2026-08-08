{ config, ... }:
{
  # The operator's home INSIDE a cage — one per project. The unix user is `dev`, the person is not.
  #
  # Dotfiles, identity, the VS Code SERVER — and the project's extensions when it is handed some.
  #
  flake.modules.homeManager.devbox-cage =
    {
      pkgs,
      lib,
      ...
    }:
    let
      # Pinned server + CLI, same expression the node home uses. Placing them is what stops Remote-SSH
      # fetching ~635MB into this cage's `$HOME`, and the wrapper it installs also suppresses the
      # agent-host server. Applied by `nix-rebuild-cage <project>` — nothing triggers it automatically yet.
      r = config.flake.lib.vscodeRemote pkgs;
    in
    {
      imports = with config.flake.modules.homeManager; [
        editors-vscode
        happygopher-vscode-taste
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
        file = r.serverFiles;
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
