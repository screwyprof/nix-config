{ pkgs ? import <nixpkgs> {}, overlays ? [] }:
let
  finalPkgs = import <nixpkgs> {
    inherit overlays;
    config.nixpkgs.overlays = overlays ++ [
      (self: super: {
        mysides = (super.callPackage ../pkgs/mysides/default.nix {
          stdenv = self.darwin.apple_sdk.stdenv;
        }).overrideAttrs (old: {
          nixpkgsHammering = {
            enable = true;
            rules = "all";
          };
        });
      })
    ];
  };
in {
  inherit (finalPkgs) mysides;
}