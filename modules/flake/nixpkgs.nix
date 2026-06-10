{ inputs, self, ... }:
let
  inherit (inputs.nixpkgs) lib;
in
{
  flake.overlays.default = lib.composeManyExtensions [
    inputs.rust-overlay.overlays.default
    (final: _: {
      alias-teacher = final.callPackage ../../pkgs/alias-teacher { };
      zim-plugins = final.callPackage ../../pkgs/zim-plugins { };
    })
    (
      final: prev:
      lib.optionalAttrs prev.stdenv.isDarwin {
        mysides = final.callPackage ../../pkgs/mysides { };
      }
    )
  ];

  perSystem =
    { system, pkgs, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
        config.allowUnfree = true;
      };

      packages = {
        inherit (pkgs) alias-teacher;
      }
      // lib.optionalAttrs pkgs.stdenv.isDarwin {
        inherit (pkgs) mysides;
      };
    };
}
