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
      devUser = {
        fullName = "Happy Gopher";
        email = "max@happygopher.nl";
      };

      supportedSystems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      nixpkgsForSystem = system: import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            mysides = final.callPackage ./pkgs/mysides {
              stdenv = if final.stdenv.isDarwin then final.darwin.apple_sdk.stdenv else final.stdenv;
            };
          })
        ];
        config.allowUnfree = true;
      };

      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};

      mkHomeConfig = { username, system }: {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = {
          inherit inputs devUser;
          isDarwin = builtins.match ".*-darwin" system != null;
        };
        backupFileExtension = "bak";
        users.${username} = { pkgs, ... }: {
          imports =
            if builtins.match ".*-darwin" system != null
            then [ ./home/users/darwin/${username} ]
            else [ ./home/users/linux/${username} ];
        };
      };

      mkDarwinConfig = { hostname, system ? "aarch64-darwin", users }:
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
                verbose = true;
                extraSpecialArgs = {
                  inherit inputs devUser;
                  isDarwin = true;
                };
                users = builtins.listToAttrs (map
                  (username: {
                    name = username;
                    value = { pkgs, ... }: {
                      imports = [ ./home/users/darwin/${username} ];
                    };
                  })
                  users);
              };
            }
          ];
        };

      mkLinuxConfig = { username, hostname, system ? "x86_64-linux" }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs devUser;
            isDarwin = false;
            pkgs = nixpkgsForSystem system;
          };
          modules = [
            ./modules/linux
            ./hosts/linux/${hostname}

            home-manager.nixosModules.home-manager
            {
              home-manager = mkHomeConfig {
                inherit username system;
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
            buildInputs = with pkgs; [ nixpkgs-fmt statix deadnix ];
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
