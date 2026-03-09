{
  description = "System configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-filter.url = "github:numtide/nix-filter";
    nix-colors.url = "github:misterio77/nix-colors";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:lnl7/nix-darwin";
      #url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      #url = "github:nix-community/home-manager/release-25.11";
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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nix-auto-follow = {
    #   url = "github:fzakaria/nix-auto-follow";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      darwin,
      home-manager,
      nix-filter,
      sops-nix,
      flake-parts,
      ...
    }:
    let
      inherit (nixpkgs) lib;

      # System administrator (for nix, homebrew, etc.)
      systemAdmin = {
        username = "happygopher";
        name = "Happy Gopher";
        email = "max@happygopher.nl";
      };

      # Common overlays
      overlays = [
        inputs.rust-overlay.overlays.default
        # Custom package overlays
        (final: _: {
          # Platform-agnostic packages
          alias-teacher = final.callPackage ./pkgs/alias-teacher { };
          bmad-method = final.callPackage ./pkgs/bmad-method { };
          markdown-tree-parser = final.callPackage ./pkgs/markdown-tree-parser { };
          zim-plugins = final.callPackage ./pkgs/zim-plugins { };
        })
        (
          final: prev:
          lib.optionalAttrs prev.stdenv.isDarwin {
            # macOS-specific packages
            mysides = final.callPackage ./pkgs/mysides { };
          }
        )
      ];

      # Generate nixpkgs for a given system
      mkPkgs =
        system:
        import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };

      # Common home-manager configuration
      mkHomeManagerConfig =
        { username, ... }:
        {
          imports = [
            inputs.sops-nix.homeManagerModules.sops
            inputs.nix-index-database.homeModules.nix-index
            ./home/modules/shared # system independent modules
            ./home/modules/darwin # system specific modules
            (./home/users/darwin + "/${username}") # user specific modules
          ];
        };

      # Darwin system configuration builder
      mkDarwinSystem =
        {
          hostname,
          system,
          users ? [ systemAdmin.username ],
          ...
        }@args:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit
              inputs
              hostname
              systemAdmin
              self
              ;
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
                  pkgs = mkPkgs system;
                };
                users = lib.genAttrs users (username: mkHomeManagerConfig { inherit username; });
              };
            }

            # Secrets management
            inputs.sops-nix.darwinModules.sops

            # Homebrew configuration
            inputs.nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                enable = true;
                #enableRosetta = true;
                mutableTaps = false;
                user = lib.mkDefault systemAdmin.username; # Admin user for Homebrew installation
                taps = {
                  "homebrew/core" = inputs.homebrew-core;
                  "homebrew/cask" = inputs.homebrew-cask;
                  "homebrew/bundle" = inputs.homebrew-bundle;
                };
              };
            }
          ]
          ++ (args.modules or [ ]);
        };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.pre-commit-hooks.flakeModule
      ];

      flake = {
        darwinConfigurations = {
          parallels = mkDarwinSystem {
            hostname = "parallels-vm";
            system = "aarch64-darwin";
            users = [
              "parallels"
              "happygopher"
            ];
          };

          macbook = mkDarwinSystem {
            hostname = "macbook";
            system = "aarch64-darwin";
            users = [ "happygopher" ];
          };
        };
      };

      perSystem =
        {
          config,
          system,
          pkgs,
          ...
        }:
        {
          _module.args.pkgs = mkPkgs system;

          treefmt = {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true;
            settings.global.excludes = [
              ".direnv/*"
              ".git/*"
              "result*"
            ];
          };

          pre-commit.settings = {
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

          devShells.default = pkgs.mkShell {
            buildInputs = [ pkgs.pre-commit ] ++ config.pre-commit.settings.enabledPackages;
            shellHook = config.pre-commit.installationScript;
          };

          packages = {
            inherit (pkgs) alias-teacher bmad-method markdown-tree-parser;
          }
          // lib.optionalAttrs pkgs.stdenv.isDarwin {
            inherit (pkgs) mysides;
          };
        };
    };
}
