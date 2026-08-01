{ config, ... }:
{
  # The operator's home INSIDE a cage — one per project. The unix user is `dev`, the person is not.
  #
  # Dotfiles, identity, and the VS Code SERVER. VS Code EXTENSIONS stay devbox's: it owns
  # `<home>/.vscode-server/extensions` per project and places the declared set before the editor
  # attaches, failing the `up` if the declaration is broken. Two owners, disjoint paths.
  #
  # That split is measured, not stylistic. The server sits behind a plain `exists()` check over
  # content-identical bytes, so a store symlink from anywhere satisfies it — which is why it can live here.
  # The extension set sits behind `extensions.json`, which the server trusts OVER the directory and which
  # nothing reconciles: delivering extensions as per-entry `home.file` symlinks means a declarative REMOVAL
  # silently never takes effect (measured — dir 7, cache 8, cold server enumerated 8 including the removed
  # one). What defeats the cache is replacing the DIRECTORY, which the server then re-scans — devbox's swap
  # does that, and so would an immutable store dir with a pre-built manifest (also measured). So extensions
  # are devbox's because that is what ships today, not because this config could not carry them.
  flake.modules.homeManager.devbox-cage =
    { pkgs, ... }:
    let
      # Pinned server + CLI, same expression the node home uses. Placing them is what stops Remote-SSH
      # fetching ~635MB into this cage's `$HOME`, and the wrapper it installs also suppresses the
      # agent-host server. Applied by `nix-rebuild-cage <project>` — nothing triggers it automatically yet.
      r = config.flake.lib.vscodeRemote pkgs;
    in
    {
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
