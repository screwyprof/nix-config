{ config, nix-colors, lib, ... }:

let
  themeLib = import ./lib { inherit lib; };
  presets = import ./presets;

  activePreset = presets.dracula;

  # Resolve scheme based on format
  resolveScheme = preset:
    if preset.format == "base24"
    then import ./schemes/${preset.scheme}.nix
    else if preset.format == "base16"
    then nix-colors.colorSchemes.${preset.scheme}
    else throw "Unsupported scheme format: ${preset.format}";

  # Helper to safely import program configs
  importProgram = program: themeName:
    let
      defaultPath = ./programs/${program}/default.nix;
      themePath = ./programs/${program}/${themeName};

      defaultImport = themeLib.requireModuleAtPath defaultPath;
      themeImport = themeLib.requireModuleAtPath themePath;
    in
    defaultImport ++ themeImport;

  # Resolve the active scheme
  activeScheme = resolveScheme activePreset;

in
{
  imports =
    # Auto-import all programs defined in the active preset (with validation already done)
    lib.flatten (lib.mapAttrsToList importProgram activePreset.programs)
    ++ [
      nix-colors.homeManagerModules.default
    ];

  colorScheme = activeScheme;
  lib.theme = themeLib;
}
