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
              stdenv = if final.stdenv.isDarwin
                then final.darwin.apple_sdk.stdenv
                else final.stdenv;
            };
          })
        ];
        config.allowUnfree = true;
      };

      system = "aarch64-darwin";
      isDarwin = builtins.match ".*-darwin" system != null;
    in {
      darwinConfigurations = {
        mac = darwin.lib.darwinSystem {
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
                users.parallels = { ... }: {
                  imports = [
                    ./hosts/users/parallels/default.nix
                  ];
                };
              };
            }
          ];
        };
      };

      # Add development shells
      devShells = forAllSystems (system: let 
        pkgs = nixpkgsForSystem system;
      in {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            mysides
            darwin.apple_sdk.frameworks.CoreServices
            darwin.apple_sdk.frameworks.Foundation
          ];
          
          shellHook = ''
            echo "Development shell for macOS tools"
            echo "Available commands:"
            echo "  mysides - Manage Finder sidebar"
          '';
        };
      });

      # Add packages output
      packages = forAllSystems (system: {
        mysides = (nixpkgsForSystem system).mysides;
      });
    };
} 
