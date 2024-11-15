{ pkgs ? import <nixpkgs> { }, overlays ? [ ] }:
let
  # Import nixpkgs with the flake's overlay
  finalPkgs = import <nixpkgs> {
    inherit overlays;
    config.allowUnfree = true;
  };
in
with finalPkgs; {
  inherit mysides;
}
