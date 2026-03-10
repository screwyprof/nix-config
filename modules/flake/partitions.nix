{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.partitions ];

  partitionedAttrs = {
    devShells = "dev";
    checks = "dev";
    formatter = "dev";
  };

  partitions.dev = {
    extraInputsFlake = ../../dev;
    module.imports = [ ../../dev/flake-module.nix ];
  };
}
