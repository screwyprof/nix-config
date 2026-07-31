{ config, ... }:
{
  # The operator's home INSIDE a cage — one per project. The unix user is `dev`, the person is not.
  #
  # Dotfiles and identity only. VS Code extensions stay devbox's: it owns
  # `<home>/.vscode-server/extensions` per project and places the declared set before the editor
  # attaches, failing the `up` if the declaration is broken. Two owners, disjoint paths.
  flake.modules.homeManager.devbox-cage = {
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
    };

    # The cage's login shell is bash and stays that way — devbox's security floor carries no user
    # preferences. So the preference lives here: zsh comes from the user profile and bash execs it for
    # INTERACTIVE shells only, leaving the session rail and `--command` invocations alone.
    programs.bash = {
      enable = true;
      initExtra = ''
        if [[ $- == *i* ]] && [[ -z "$ZSH_VERSION" ]] && command -v zsh > /dev/null; then
          exec zsh -l
        fi
      '';
    };

    programs.home-manager.enable = true;
  };
}
