{ config, ... }:
{
  darwinHosts.macbook = {
    users.happygopher = [ config.flake.modules.homeManager.happygopher-darwin ];
  };
}
