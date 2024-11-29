{
  description = "System configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:Homebrew/homebrew-bundle";
      flake = false;
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , nix-index-database
    , darwin
    , home-manager
    , pre-commit-hooks
    , nix-homebrew
    , homebrew-core
    , homebrew-cask
    , homebrew-bundle
    , rust-overlay
    , ...
    }@inputs:
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
          rust-overlay.overlays.default
          (final: _: {
            navi = final.callPackage ./pkgs/navi { };
            tinty = final.callPackage ./pkgs/tinty { };
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

            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                user = "happygopher";

                enable = true;
                enableRosetta = true;
                mutableTaps = false;

                taps = {
                  "homebrew/core" = inputs.homebrew-core;
                  "homebrew/cask" = inputs.homebrew-cask;
                  "homebrew/bundle" = inputs.homebrew-bundle;
                };
              };
            }

            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "bak";
                extraSpecialArgs = {
                  inherit inputs devUser;
                  isDarwin = true;
                };
                users = builtins.listToAttrs (map
                  (username: {
                    name = username;
                    value = { ... }: {
                      imports = [
                        ./home/users/darwin/${username}
                        nix-index-database.hmModules.nix-index
                      ];
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
