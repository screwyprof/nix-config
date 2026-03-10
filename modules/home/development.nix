{ config, ... }:
{
  flake.modules.homeManager.development = {
    imports = with config.flake.modules.homeManager; [
      dev-git
      dev-nix
      dev-direnv
      dev-node
      dev-python
      dev-vscode
      dev-claude
      dev-containers
    ];
  };
}
