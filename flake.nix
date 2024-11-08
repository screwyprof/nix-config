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
      supportedSystems = [ "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Create nixpkgs config for each system
      nixpkgsForSystem = system: import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            mysides = final.callPackage ./pkgs/mysides {
              stdenv = if system == "aarch64-darwin" 
                then final.darwin.apple_sdk.stdenv
                else final.stdenv;
            };
            finder-sidebar-editor = final.callPackage ./pkgs/finder-sidebar-editor {};
          })
        ];
        config.allowUnfree = true;
      };

    in {
      darwinConfigurations = {
        mac = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { 
            inherit inputs devUser; 
            pkgs = nixpkgsForSystem "aarch64-darwin";
          };
          modules = [
            ./hosts/darwin
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs devUser; };
                users.parallels = { ... }: {
                  imports = [
                    ./home/users/parallels/default.nix
                    ./home/users/parallels/darwin.nix
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
            finder-sidebar-editor
          ];
          
          shellHook = ''
            echo "Development shell for macOS tools"
            echo "Available commands:"
            echo "  mysides - Manage Finder sidebar"
            echo "  finder-sidebar-editor - Python Finder sidebar editor"
            
            # Create a working directory for development
            mkdir -p dev
            cp ${pkgs.finder-sidebar-editor}/bin/finder-sidebar-editor.py dev/
            chmod +w dev/finder-sidebar-editor.py
            
            echo "Script copied to dev/finder-sidebar-editor.py for editing"
          '';
        };
      });

      # Add packages output
      packages = forAllSystems (system: {
        mysides = (nixpkgsForSystem system).mysides;
      });
    };
} 
