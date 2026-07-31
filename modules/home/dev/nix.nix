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

          ${lib.optionalString pkgs.stdenv.isLinux ''
            # The two devbox surfaces are STANDALONE homeConfigurations — neither has a host config to
            # hang them off, so there is no `nixos-rebuild` equivalent: you build the activation package
            # and run it. Same `.#` convention as nix-rebuild — run these from inside this repo.
            function nix-rebuild-devbox() {
              local out
              out=$(nix build --no-link --print-out-paths ".#homeConfigurations.devbox-host.activationPackage") || return
              "$out/activate"
            }

            # Built on the NODE, activated INSIDE the cage. Pass the STORE PATH, never ./result: a cage
            # binds /nix/store but not this repo, so a result symlink out here is invisible in there.
            function nix-rebuild-cage() {
              local project="$1"
              if [[ -z "$project" ]]; then
                echo "usage: nix-rebuild-cage <project>" >&2
                return 2
              fi
              local out
              out=$(nix build --no-link --print-out-paths ".#homeConfigurations.devbox-cage.activationPackage") || return
              sudo machinectl shell "dev@$project" /run/current-system/sw/bin/bash -lc "$out/activate"
            }
          ''}

          function dev() {
            local shell="$1"
            shift
            local flake_ref
            if [[ -n "''${NIX_DEVX:-}" ]]; then
              flake_ref="path:$NIX_DEVX?dir=shells/$shell"
            else
              flake_ref="github:screwyprof/nix-devx?dir=shells/$shell"
            fi
            if [ $# -eq 0 ]; then
              nix develop "$flake_ref" --no-write-lock-file
            else
              nix develop "$flake_ref" --no-write-lock-file --command "$@"
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
