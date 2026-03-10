{ config, ... }:
{
  flake.modules.homeManager.cli = {
    imports = with config.flake.modules.homeManager; [
      cli-zsh
      cli-moor
      cli-bat
      cli-fzf
      cli-cheat
      cli-tldr
      cli-zoxide
      cli-secrets
    ];
  };
}
