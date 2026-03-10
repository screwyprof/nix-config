{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  systems = [
    "aarch64-darwin"
    "aarch64-linux"
  ];
}
