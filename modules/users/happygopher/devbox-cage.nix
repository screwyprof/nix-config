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
      # agent-host server. devbox ACTIVATES this at every cage `up`, from the ref `vm home-flake`
      # persists (devbox#360) — unless the project declares its own `devbox.<system>.home`, which
      # supersedes it (devbox#501). `nix-rebuild-cage <project>` is the manual path, for applying a
      # change without an `up`.
      r = config.flake.lib.vscodeRemote pkgs;
    in
    {
      imports = with config.flake.modules.homeManager; [
        editors-vscode
        happygopher-vscode-taste
        happygopher-identity
        dev-direnv # loads the project devshell on cd — why anything else is on PATH
        dev-git
        # UX only — the cage's container capability supplies `docker`/`docker-compose` itself, as a
        # wrapper over rootless podman. Importing `dev-containers` instead would add a second client
        # earlier on PATH with no daemon behind it.
        dev-containers-shell
        core-vim
        cli-bat
        cli-eza
        cli-fzf
        cli-moor
        cli-zoxide
        cli-zsh
      ];

      # Always `dev` at `/home/dev`, whichever project: identity lives in the bind mounts, not the user.
      home = {
        username = "dev";
        homeDirectory = "/home/dev";
        stateVersion = "24.11";
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
