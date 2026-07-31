{ lib, ... }:
{
  # Declare `flake.lib` so multiple modules can contribute to it.
  #
  # flake-parts does not declare this output, so an undeclared `flake.lib` accepts exactly ONE definition
  # and any second module touching it fails with "defined multiple times … definitions can't be merged
  # automatically". That is fine until the repo has two lib modules — which it now does (the extension
  # catalog and the remote-server pin).
  #
  # `lazyAttrsOf raw`: values are functions and derivations that must not be evaluated to be merged, and
  # `raw` keeps the module system from recursing into them.
  options.flake.lib = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = "Repo-local helpers exposed as flake outputs, contributed by any module.";
  };
}
