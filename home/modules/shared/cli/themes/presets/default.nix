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
    fallbackTheme = "dracula";
    programs = {
      # bat doesn't have gruvbox theme yet, will fallback to dracula
      # bat = ../programs/bat/gruvbox;
    };
  };
}
