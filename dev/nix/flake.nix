{
  description = "Development environment for nix configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-checker.url = "github:DeterminateSystems/flake-checker";
  };

  outputs = { nixpkgs, flake-checker }: {
    devShells = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" ]
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          mkScript = name: text: pkgs.writeScriptBin name text;
          scripts = with pkgs; [
            (mkScript "nix-check" "nix flake check")
            (mkScript "nix-cleanup" "sudo -H nix-collect-garbage -d")
            (mkScript "nix-optimise" "sudo -H nix store optimise 2>&1 | grep -v 'warning: skipping suspicious writable file'")
            (mkScript "nix-update" "nix flake update")
            (mkScript "nix-update-nixpkgs" "nix flake lock --update-input nixpkgs")
            (mkScript "nix-fmt" "nixpkgs-fmt .")
            (mkScript "nix-lint" "nixpkgs-lint")
            (mkScript "nix-check-flake" "${flake-checker.packages.${system}.default}/bin/flake-checker")
          ];
        in
        {
          default = pkgs.mkShell {
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
              flake-checker.packages.${system}.default
            ] ++ scripts;
          };
        });
  };
}
