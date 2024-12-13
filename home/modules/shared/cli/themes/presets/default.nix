{ nix-colors }:
{
  dracula = {
    scheme = import ../schemes/base24-dracula.nix;
    programs = {
      zsh = ../programs/zsh/dracula;
      bat = ../programs/bat/dracula;
    };
  };

  gruvbox = {
    scheme = {
      inherit (nix-colors.colorSchemes.gruvbox-dark-medium) name slug author palette;
      variant = "dark";
    };
    programs = {
      zsh = ../programs/zsh/gruvbox;
      bat = ../programs/bat/gruvbox-dark;
    };
  };
}
