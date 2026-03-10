{
  description = "Zim Framework module for Home Manager";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = _: {
    homeManagerModules.zimfw = import ./modules/zimfw.nix;
    homeManagerModules.default = import ./modules/zimfw.nix;
  };
}
