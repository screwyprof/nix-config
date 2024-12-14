{
  description = "System configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-colors.url = "github:misterio77/nix-colors";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        brew-src = {
          url = "github:Homebrew/brew";
          flake = false;
        };
      };
    };
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

  outputs = inputs@{ self, nixpkgs, darwin, home-manager, ... }:
    let
      inherit (nixpkgs) lib;

      # System administrator (for nix, homebrew, etc.)
      systemAdmin = {
        username = "happygopher";
        fullName = "Happy Gopher";
        email = "max@happygopher.nl";
      };

      # Systems supported
      supportedSystems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" ];
      forAllSystems = lib.genAttrs supportedSystems;

      # Common overlays
      overlays = [
        inputs.rust-overlay.overlays.default
        (final: _: {
          # Platform-agnostic packages
          navi = final.callPackage ./pkgs/navi { };
          tinty = final.callPackage ./pkgs/tinty { };
        })
        (final: prev: lib.optionalAttrs prev.stdenv.isDarwin {
          # macOS-specific packages
          mysides = final.callPackage ./pkgs/mysides {
            inherit (final.darwin.apple_sdk) stdenv;
          };
        })
      ];

      # Generate nixpkgs for each system
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        });

      # Common home-manager configuration
      mkHomeManagerConfig = { username, ... }: {
        imports = [
          ./home/modules/shared # system independent modules
          ./home/modules/darwin # system specific modules
          (./home/users/darwin + "/${username}") # user specific modules
          inputs.nix-index-database.hmModules.nix-index
        ];
        nixpkgs.overlays = [ inputs.rust-overlay.overlays.default ];
      };

      # Darwin system configuration builder
      mkDarwinSystem = { hostname, system, users ? [ systemAdmin.username ], ... }@args:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit inputs hostname systemAdmin;
          };
          modules = [
            # Base configuration
            ./hosts/darwin/shared
            ./hosts/darwin/${hostname}

            # User configuration
            {
              users.users = lib.genAttrs users (username: {
                name = username;
                home = "/Users/${username}";
              });
            }

            # Home manager configuration
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "bak";
                extraSpecialArgs = {
                  inherit inputs systemAdmin;
                  inherit (inputs) nix-colors;
                  pkgs = nixpkgsFor.${system};
                };
                users = lib.genAttrs users (username: mkHomeManagerConfig { inherit username; });
              };
            }

            # Homebrew configuration
            inputs.nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                enable = true;
                enableRosetta = true;
                mutableTaps = false;
                user = lib.mkDefault systemAdmin.username; # Admin user for Homebrew installation
                taps = {
                  "homebrew/core" = inputs.homebrew-core;
                  "homebrew/cask" = inputs.homebrew-cask;
                  "homebrew/bundle" = inputs.homebrew-bundle;
                };
              };
            }
          ] ++ (args.modules or [ ]);
        };

      # System configurations
      darwinConfigurations = {
        parallels = mkDarwinSystem {
          hostname = "parallels-vm";
          system = "aarch64-darwin";
          users = [ "parallels" "happygopher" ];
        };

        macbook = mkDarwinSystem {
          hostname = "macbook";
          system = "aarch64-darwin";
          users = [ "happygopher" ];
        };
      };

      # Development shells
      devShells = forAllSystems (system:
        let pkgs = nixpkgsFor.${system}; in {
          default = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
          };
        });

      # Packages
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        lib.optionalAttrs pkgs.stdenv.isDarwin {
          inherit (pkgs) mysides;
        });

      # Checks
      checks = forAllSystems (system: {
        pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
            statix.enable = true;
            deadnix.enable = true;
            nil.enable = true;
          };
        };
      });
    in
    {
      inherit darwinConfigurations devShells packages checks;
    };
}
