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
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs = { self, nixpkgs, darwin, home-manager, pre-commit-hooks, ... }@inputs:
    let

      devUser = {
        fullName = "Happy Gopher";
        email = "max@happygopher.nl";
      };

      supportedSystems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      nixpkgsForSystem = system: import nixpkgs {
        inherit system;
        overlays = [
          (final: _: {
            #tinty = final.callPackage ./pkgs/tinty { };
            mysides = final.callPackage ./pkgs/mysides {
              stdenv = if final.stdenv.isDarwin then final.darwin.apple_sdk.stdenv else final.stdenv;
            };
          })
        ];
        config.allowUnfree = true;
      };

      mkDarwinConfig = { hostname, system, users }:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit inputs devUser;
            isDarwin = true;
            pkgs = nixpkgsForSystem system;
          };
          modules = [
            ./hosts/darwin/shared
            ./hosts/darwin/${hostname}

            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "bak";
                #verbose = true;
                extraSpecialArgs = {
                  inherit inputs devUser;
                  isDarwin = true;
                };
                users = builtins.listToAttrs (map
                  (username: {
                    name = username;
                    value = { ... }: {
                      imports = [ ./home/users/darwin/${username} ];
                    };
                  })
                  users);
              };
            }
          ];
        };
    in
    {
      darwinConfigurations = {
        parallels = mkDarwinConfig {
          hostname = "parallels-vm";
          system = "aarch64-darwin";
          users = [ "parallels" "testuser" ];
        };

        macbook = mkDarwinConfig {
          hostname = "macbook";
          system = "aarch64-darwin";
          users = [ "happygopher" ];
        };
      };

      devShells = forAllSystems (system:
        let pkgs = nixpkgsForSystem system;
        in {
          default = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            buildInputs = [
              pkgs.mysides
              pkgs.darwin.apple_sdk.frameworks.CoreServices
              pkgs.darwin.apple_sdk.frameworks.Foundation
              self.checks.${system}.pre-commit-check.enabledPackages
            ];
          };
        });

      packages = forAllSystems (system: {
        inherit (nixpkgsForSystem system) mysides;
      });

      checks = forAllSystems (system: {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
            statix.enable = true;
            deadnix.enable = true;
            nil.enable = true;
          };
        };
      });
    };
} 
