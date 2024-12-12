{ config, lib, nix-colors, ... }:

let
  presets = import ./presets;
  activePreset = presets.dracula;

  # Helper to safely import program configs
  importIfExists = program:
    if activePreset.programs.${program} != null
    then [ activePreset.programs.${program} ]
    else [ ];

  # Convert hex string to decimal using TOML parsing
  hexToDec = hex: (builtins.fromTOML "n = 0x${hex}").n;
in
{
  imports = [
    nix-colors.homeManagerModules.default
    ./programs/zsh/module.nix
  ]
  ++ importIfExists "zsh"
  ++ importIfExists "bat"
  ;

  config = {
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
  };
}
