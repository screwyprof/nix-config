{
  description = "System configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    nix-filter.url = "github:numtide/nix-filter";
    nix-colors.url = "github:misterio77/nix-colors";
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
    };
    homebrew-core = {
      url = "github:Homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:Homebrew/homebrew-cask";
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
  outputs = inputs@{ self, nixpkgs, darwin, home-manager, pre-commit-hooks, nix-filter, ... }:
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
        # Custom packages overlay
        (final: _: {
          # Platform-agnostic packages
          alias-teacher = final.callPackage ./pkgs/alias-teacher { };
          bmad-method = final.callPackage ./pkgs/bmad-method { };
          markdown-tree-parser = final.callPackage ./pkgs/markdown-tree-parser { };
          zim-plugins = final.callPackage ./pkgs/zim-plugins { };
        })
        (final: prev: lib.optionalAttrs prev.stdenv.isDarwin {
          # macOS-specific packages
          mysides = final.callPackage ./pkgs/mysides { };
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
          inputs.nix-index-database.homeModules.nix-index
        ];
      };

      # Darwin system configuration builder
      mkDarwinSystem = { hostname, system, users ? [ systemAdmin.username ], ... }@args:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit inputs hostname systemAdmin self;
          };
          modules = [
            # Host configuration
            ./hosts/darwin/shared
            ./hosts/darwin/${hostname}

            # System configuration
            {
              system.primaryUser = systemAdmin.username;
            }

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

      # Development shells
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
          };
        });

      # Checks
      checks = forAllSystems (system: {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = nix-filter.lib.filter {
            root = self;
            include = [
              (nix-filter.lib.matchExt "nix")
              "flake.lock"
            ];
            exclude = [
              ".direnv"
              ".git"
              "result"
            ];
          };
          hooks = {
            nixpkgs-fmt.enable = true;
            statix.enable = true;
            deadnix = {
              enable = true;
              settings = {
                noLambdaPatternNames = true;
              };
            };
            nil.enable = true;
            flake-checker.enable = true;
          };
        };
      });

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

      # Packages
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          inherit (pkgs) alias-teacher bmad-method markdown-tree-parser;
        } // lib.optionalAttrs pkgs.stdenv.isDarwin {
          inherit (pkgs) mysides;
        });
    in
    {
      inherit darwinConfigurations devShells packages checks;
    };
}
