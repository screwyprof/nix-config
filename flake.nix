{
  description = "System configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager, ... }@inputs:
    let
      # Define your development identity
      devUser = {
        fullName = "Happy Gopher";
        email = "max@happygopher.nl";
      };

      # Systems supported
      supportedSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Create nixpkgs config for each system
      nixpkgsForSystem = system: import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            mysides = final.callPackage ./pkgs/mysides {
              stdenv =
                if final.stdenv.isDarwin
                then final.darwin.apple_sdk.stdenv
                else final.stdenv;
            };
          })
        ];
        config.allowUnfree = true;
      };

      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      isDarwin = builtins.match ".*-darwin" system != null;

      # Common darwin configuration
      mkDarwinConfig = { username }: darwin.lib.darwinSystem {
        inherit system;
        specialArgs = {
          inherit inputs devUser isDarwin;
          pkgs = nixpkgsForSystem system;
        };
        modules = [
          ./hosts/darwin
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs devUser isDarwin;
              };
              backupFileExtension = "bak";
              users.${username} = { pkgs, ... }: {
                imports = [
                  ./hosts/users/${username}/default.nix
                ];
              };
            };
          }
        ];
      };
    in
    {
      darwinConfigurations = {
        # Configuration for Parallels VM
        parallels = mkDarwinConfig {
          username = "parallels";
        };

        # Configuration for host MacBook
        macbook = mkDarwinConfig {
          username = "happygopher";
        };
      };

      # Rest of the configuration remains the same
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsForSystem system;
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              mysides
              pkgs.darwin.apple_sdk.frameworks.CoreServices
              pkgs.darwin.apple_sdk.frameworks.Foundation
            ];

            shellHook = ''
              echo "Development shell for macOS tools"
              echo "Available commands:"
              echo "  mysides - Manage Finder sidebar"
            '';
          };
        });

      packages = forAllSystems (system: {
        inherit (nixpkgsForSystem system) mysides;
      });

      checks.${system} = {
        formatting = pkgs.runCommand "check-formatting"
          {
            buildInputs = with pkgs; [
              nixpkgs-fmt
              statix
              deadnix
            ];
          } ''
          cd ${self}
          nixpkgs-fmt --check .
          statix check .
          deadnix .
          touch $out
        '';
      };
    };
} 
