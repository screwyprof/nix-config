{ config, lib, nix-colors, ... }:

let
  presets = import ./presets { inherit nix-colors; };
  activePreset = presets.gruvbox;

  # Helper to get program theme config, with fallback support
  getProgramTheme = program:
    let
      requestedTheme = activePreset.programs.${program} or null;
      fallbackTheme = presets.${activePreset.fallbackTheme or "dracula"}.programs.${program} or null;
    in
    if requestedTheme != null then requestedTheme
    else fallbackTheme;

  # Helper to safely import program configs
  importProgram = program:
    let
      baseModule = ./programs/${program}/default.nix;
      themeModule = getProgramTheme program;
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

  # Convert hex string to decimal using TOML parsing
  hexToDec = hex: (builtins.fromTOML "n = 0x${hex}").n;
in
{
  imports = [
    nix-colors.homeManagerModules.default
  ]
  ++ importProgram "zsh"
  ++ importProgram "bat"
  ;

  colorScheme = activePreset.scheme;
  lib.theme = {
    # Convert hex to RGB components
    hexToRGB = hex: {
      r = hexToDec (builtins.substring 0 2 hex);
      g = hexToDec (builtins.substring 2 2 hex);
      b = hexToDec (builtins.substring 4 2 hex);
    };

    # Format RGB values for ANSI sequences
    formatRGB = hex:
      let rgb = config.lib.theme.hexToRGB hex;
      in "${toString rgb.r}//${toString rgb.g}//${toString rgb.b}";
  };
}
