{ config, nix-colors, lib, ... }:

let
  themeLib = import ./lib { inherit lib; };

  presets = import ./presets { inherit nix-colors; };
  activePreset = presets.dracula;

  # Helper to safely import program configs
  importProgram = program:
    let
      baseModule = ./programs/${program}/default.nix;
      themeModule = activePreset.programs.${program} or null;
      baseImport =
        if builtins.pathExists baseModule
        then [ (import baseModule) ]
        else [ ];
      themeImport =
        if themeModule != null
        then [ (import themeModule) ]
        else [ ];
    in
    baseImport ++ themeImport;

in
{
  imports =
    importProgram "zsh"
    ++ importProgram "bat"
    ++ importProgram "iterm2"
    ++ [
      nix-colors.homeManagerModules.default
    ];

  colorScheme = activePreset.scheme;
  lib.theme = themeLib;
}
