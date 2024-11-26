{ lib, ... }:
{
  imports = [
    ./modules/bat
    # ./tools/zsh.nix
    # ./tools/fzf.nix
    # ./tools/eza.nix
    # ... other tool-specific theme modules
  ];

  options.theme = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "dracula";
      description = "Name of the theme to use";
    };

    spec = lib.mkOption {
      type = lib.types.str;
      default = "base24";
      description = "Specification of the theme to use";
    };
  };
}
