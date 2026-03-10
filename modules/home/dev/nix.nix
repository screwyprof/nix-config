{
  flake.modules.homeManager.dev-nix =
    { pkgs, lib, ... }:
    {
      home.packages = with pkgs; [
        cachix
        nixpkgs-fmt
        statix
        deadnix
        nixpkgs-lint
        nil
        nix-prefetch-github
        nix-prefetch-git
        nixpkgs-hammering
        flake-checker
      ];

      programs.nix-index = {
        enable = true;
        enableZshIntegration = true;
      };

      programs.zsh = {
        initContent = lib.mkAfter ''
          function nix-rebuild() {
            if [[ "$(uname)" == "Darwin" ]]; then
              sudo --preserve-env darwin-rebuild switch --flake ".#$1"
            else
              nixos-rebuild switch --flake ".#$1"
            fi
          }

          function dev() {
            local shell="$1"
            shift  # Remove first argument
            if [ $# -eq 0 ]; then
              # No additional arguments, just enter the shell
              nix develop "$HOME/nix-config/dev/$shell" --impure
            else
              # Execute command in the shell
              nix develop "$HOME/nix-config/dev/$shell" --impure --command "$@"
            fi
          }
        '';

        shellAliases = {
          nix-check = "nix flake check";
          nix-fmt = "nixpkgs-fmt .";
          nix-lint = "nixpkgs-lint .";
          nix-check-flake = "flake-checker";
          nix-update = "nix flake update";
          nix-update-nixpkgs = "nix flake update nixpkgs";
          nix-cleanup = "sudo -H nix-collect-garbage --delete-older-than 7d && sudo -H nix store optimise";
          nix-store-size = "du -sh /nix/store";
        }
        // (
          if pkgs.stdenv.isDarwin then
            {
              nix-rebuild-host = "nix-rebuild macbook";
            }
          else
            { }
        );
      };
    };
}
