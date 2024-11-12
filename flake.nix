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
      supportedSystems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" ];
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

      #  home-manager configuration
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
            # Add platform-specific configs
            if builtins.match ".*-darwin" system != null
            then [ ./home/users/darwin/${username} ]
            else [ ./home/users/linux/${username} ];
        };
      };

      # Darwin configuration
      mkDarwinConfig = { hostname, system ? "aarch64-darwin", users }:
        let
          pkgs = nixpkgsForSystem system;
        in
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit inputs devUser;
            isDarwin = true;
            pkgs = nixpkgsForSystem system;
          };
          modules = [
            # Shared Darwin system settings
            ./hosts/darwin/shared
            # Machine-specific configuration
            ./hosts/darwin/${hostname}

            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit inputs devUser;
                  isDarwin = builtins.match ".*-darwin" system != null;
                };
                backupFileExtension = "bak";
                # Configure multiple users
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

      # Linux configuration
      mkLinuxConfig = { username, hostname, system ? "x86_64-linux" }: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs devUser;
          isDarwin = false;
          pkgs = nixpkgsForSystem system;
        };
        modules = [
          # System-wide modules
          ./modules/linux
          # Machine-specific configuration
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
        # Configuration for Parallels VM with multiple users
        parallels = mkDarwinConfig {
          hostname = "parallels-vm";
          system = "aarch64-darwin";
          users = [ "parallels" "testuser" ]; # Support multiple users
        };

        # Configuration for host MacBook
        macbook = mkDarwinConfig {
          hostname = "macbook";
          system = "aarch64-darwin";
          users = [ "happygopher" ];
        };

        test = mkDarwinConfig {
          username = "testuser";
          hostname = "test";
          system = "aarch64-darwin";
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
