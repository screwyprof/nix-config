# System-wide Nix configuration
{ pkgs, ... }:

{
  # System-specific rebuild commands
  programs.zsh = {
    initExtra = ''
      function nix-rebuild() {
        if [[ "$(uname)" == "Darwin" ]]; then
          darwin-rebuild switch --flake ".#$1"
        else
          nixos-rebuild switch --flake ".#$1"
        fi
      }

      function dev() {
        local shell="$1"
        shift  # Remove first argument
        if [ $# -eq 0 ]; then
          # No additional arguments, just enter the shell
          nix develop "$HOME/nix-config/dev/$shell"
        else
          # Execute command in the shell
          nix develop "$HOME/nix-config/dev/$shell" --command "$@"
        fi
      }
    '';

    shellAliases =
      if pkgs.stdenv.isDarwin then {
        nix-rebuild-host = "nix-rebuild macbook";
        nix-rebuild-mac = "nix-rebuild parallels";
      } else { };
  };
}
