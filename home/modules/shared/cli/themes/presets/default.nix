{
  dracula = {
    scheme = import ../schemes/base24-dracula.nix;
    programs = {
      zsh = (import ../programs/zsh).dracula;
      bat = (import ../programs/bat).dracula;
    };
  };

  gruvbox = {
    scheme = import ../schemes/base24-gruvbox.nix;
    programs = {
      bat = (import ../programs/bat).gruvbox or null;
    };
  };
}
