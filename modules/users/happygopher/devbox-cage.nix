{ config, ... }:
{
  # The operator's home INSIDE a devbox cage — one per project, since a cage home is per-project.
  # The unix user is `dev`, but the person is the same, hence `happygopher-identity`.
  #
  # SCOPE, deliberately narrow: dotfiles and identity only. VS Code extensions are NOT here, because
  # devbox already owns `<home>/.vscode-server/extensions` per project — it places the declared set
  # before the editor attaches and fails the `up` if the declaration is broken, a moment home-manager has
  # no equivalent of. Two owners, disjoint paths, no fight over the same directory.
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

    # A cage's occupant is always `dev` at `/home/dev` (devbox `host/sandbox/base.nix`), whichever project
    # the cage is for — project identity lives in the bind mounts, not in the user.
    home = {
      username = "dev";
      homeDirectory = "/home/dev";
      stateVersion = "24.11";
    };

    # devbox sets the cage user's login shell to bash (`host/sandbox/base.nix`), and deliberately so —
    # the security floor carries no user preferences, which is why `cage-tooling`/`vm-tooling` were
    # removed from the closures. Changing that shell would put a preference back into the TCB.
    #
    # So the preference stays HERE: home-manager puts `zsh` in the user's own profile, and bash hands off
    # to it for interactive sessions only. Non-interactive uses (`machinectl shell … --command`, scripts,
    # the devbox session rail) keep bash and are unaffected.
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
