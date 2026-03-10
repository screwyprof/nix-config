{ config, ... }:
{
  flake.modules.homeManager.core = {
    imports = with config.flake.modules.homeManager; [
      core-fonts
      core-gnu-utils
      core-vim
      core-fastfetch
      core-safe-rm
    ];
  };
}
