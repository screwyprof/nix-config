{ lib }:

let
  # Convert hex string to decimal using TOML parsing
  hexToDec = hex: (builtins.fromTOML "n = 0x${hex}").n;

  # Convert hex to RGB components
  hexToRGB = hex: {
    r = hexToDec (builtins.substring 0 2 hex);
    g = hexToDec (builtins.substring 2 2 hex);
    b = hexToDec (builtins.substring 4 2 hex);
  };

  # Format RGB values for ANSI sequences
  formatRGB = hex:
    let rgb = hexToRGB hex;
    in "${toString rgb.r}//${toString rgb.g}//${toString rgb.b}";
in
{
  inherit hexToRGB formatRGB;

  # Import a module at path, requiring it to exist or throwing helpful error
  requireModuleAtPath = path:
    if builtins.pathExists path
    then [ (import path) ]
    else
      throw "Theme path not found: ${toString path}
Please check if this theme exists for the specified program";

  # Additional helper functions we might add later
  # inherit (lib) mkOption types; # Re-export common lib functions
}
