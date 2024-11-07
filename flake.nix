{
  description = "Nix system configurations";

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
      systemSettings = {
        system = "aarch64-darwin";
        hostname = "mac";
        username = "parallels";  
      };

      pkgs = import nixpkgs {
        inherit (systemSettings) system;
        config = {
          allowUnfree = true;
        };
      };
      lib = nixpkgs.lib;
    in
    {
      darwinConfigurations = {
        ${systemSettings.hostname} = darwin.lib.darwinSystem {
          inherit (systemSettings) system;
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/darwin/default.nix
            
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit pkgs;
                };
                users.${systemSettings.username} = {
                  imports = [
                    ./home/profiles/default.nix
                  ];
                  home = {
                    username = lib.mkForce systemSettings.username;
                    homeDirectory = lib.mkForce "/Users/${systemSettings.username}";
                  };
                };
              };
            }
          ];
        };
      };
    };
} 