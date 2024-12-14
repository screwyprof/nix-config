{
  description = "Development environment for nix configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs = { nixpkgs, pre-commit-hooks }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" ];
      mkScript = pkgs: name: text: pkgs.writeScriptBin name text;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          scripts = with pkgs; [
            (mkScript pkgs "nix-check" "nix flake check")
            (mkScript pkgs "nix-cleanup" "sudo -H nix-collect-garbage -d")
            (mkScript pkgs "nix-optimise" "sudo -H nix store optimise 2>&1 | grep -v 'warning: skipping suspicious writable file'")
            (mkScript pkgs "nix-update" "nix flake update")
            (mkScript pkgs "nix-update-nixpkgs" "nix flake lock --update-input nixpkgs")
            (mkScript pkgs "nix-fmt" "nixpkgs-fmt .")
            (mkScript pkgs "nix-lint" "nixpkgs-lint")
          ];
        in
        {
          default = pkgs.mkShell {
            inherit (pre-commit-hooks.lib.${system}.run {
              src = ../../.;
              hooks = {
                nixpkgs-fmt.enable = true;
                statix = {
                  enable = true;
                  excludes = [ ".direnv" ];
                };
                deadnix.enable = true;
                nil.enable = true;
              };
              excludes = [ "^.direnv/" ];
            }) shellHook;

            buildInputs = with pkgs; [
              # Nix formatting and linting
              nixpkgs-fmt
              statix
              deadnix
              nixpkgs-lint
              nil

              # Nix development tools
              nix-prefetch-github
              nix-prefetch-git
              nixpkgs-hammering

              # Build tools
              gnumake
            ] ++ scripts;
          };
        });
    };
}
