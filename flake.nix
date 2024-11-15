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
    nixpkgs-hammering = {
      url = "github:jtojnar/nixpkgs-hammering";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-eval-jobs.url = "github:nix-community/nix-eval-jobs";
  };

  outputs = { self, nixpkgs, darwin, home-manager, nixpkgs-hammering, nix-eval-jobs, ... }@inputs:
    let
      inherit (nixpkgs) lib;

      devUser = {
        fullName = "Happy Gopher";
        email = "max@happygopher.nl";
      };

      supportedSystems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      nixpkgsForSystem = system: import nixpkgs {
        inherit system;
        overlays = [
          nixpkgs-hammering.overlays.default

          (final: prev: {
            mysides = (final.callPackage ./pkgs/mysides {
              stdenv = if final.stdenv.isDarwin then final.darwin.apple_sdk.stdenv else final.stdenv;
            }).overrideAttrs (old: {
              nixpkgsHammering = true;
            });
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
                #verbose = true;
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

      checks = forAllSystems (system:
        let
          pkgs = nixpkgsForSystem system;
        in
        {
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

          hammering = pkgs.runCommand "check-hammering"
            {
              buildInputs = [ nixpkgs-hammering.packages.${system}.default ];
            } ''
            set -euo pipefail
              
            # Create minimal test file with all rules enabled
            cat > ./default.nix << 'EOF'
            { pkgs ? import <nixpkgs> {}, overlays ? [] }:
            let
              finalPkgs = import <nixpkgs> {
                inherit overlays;
                config.nixpkgs.overlays = overlays ++ [
                  (self: super: {
                    mysides = (super.callPackage ${./pkgs/mysides/default.nix} {
                      stdenv = self.darwin.apple_sdk.stdenv;
                    }).overrideAttrs (old: {
                      nixpkgsHammering = {
                        enable = true;
                        rules = "all";
                      };
                    });
                  })
                ];
              };
            in {
              inherit (finalPkgs) mysides;
            }
            EOF

            # Run hammering and capture output
            nixpkgs-hammer -f ./default.nix mysides 2>&1 | \
              grep -v "warning: creating directory '/homeless-shelter" | \
              grep -v "error: build log" | \
              grep -v "notice: no-build-output" > hammer_output.txt

            # Create output directory
            mkdir -p $out

            # Extract and format warnings
            {
              echo "=== nixpkgs-hammering Check Results ==="
              echo ""
                
              if grep -q "warning:" hammer_output.txt; then
                echo "⚠️  Warnings found:"
                echo "----------------------------------------"
                grep -A2 "warning:" hammer_output.txt | grep -v "See:"
                echo "----------------------------------------"
                echo ""
                echo "For details, see:"
                grep "See:" hammer_output.txt
                  
                # Save full output
                mkdir -p $out/nix-support
                cp hammer_output.txt $out/nix-support/
                  
                # Exit with error to indicate warnings were found
                exit 1
              else
                echo "✅ No issues found"
              fi
            } | tee $out/result.txt

            # Always create a new result to prevent caching
            date > $out/timestamp
          '';

          inherit (pkgs) mysides;
        });
    };
} 
