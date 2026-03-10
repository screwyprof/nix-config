{
  description = "Terminal color theming module for Home Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs =
    { nix-colors, ... }:
    let
      themeModule = import ./. { inherit nix-colors; };
    in
    {
      homeManagerModules.themes = themeModule;
      homeManagerModules.default = themeModule;
    };
}
