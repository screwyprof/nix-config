{
  inputs,
  lib,
  config,
  ...
}:
let
  darwinHostModule = _: {
    options = {
      system = lib.mkOption {
        type = lib.types.str;
        default = "aarch64-darwin";
      };

      modules = lib.mkOption {
        type = with lib.types; listOf deferredModule;
        default = with config.flake.modules.darwin; [
          system
          spotlight
        ];
        description = "Darwin system modules for this host.";
      };

      users = lib.mkOption {
        type = with lib.types; attrsOf (listOf deferredModule);
        default = { };
        description = "Users on this host. Keys are usernames, values are per-user HM modules.";
      };
    };
  };

  defaultHomeManagerModules = with config.flake.modules.homeManager; [
    core
    cli
    development
    darwin-brew
    darwin-colima
    darwin-coredumps
  ];
in
{
  options = {
    darwinHosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule [ darwinHostModule ]);
      default = { };
    };
  };

  config = {
    flake.darwinConfigurations =
      let
        usernames = hostOpts: lib.attrNames hostOpts.users;

        mkHost =
          _hostname: hostOpts:
          inputs.darwin.lib.darwinSystem {
            inherit (hostOpts) system;
            modules = hostOpts.modules ++ [

              # User configuration
              {
                spotlight.users = usernames hostOpts;
                users.users = lib.genAttrs (usernames hostOpts) (username: {
                  name = username;
                  home = "/Users/${username}";
                });
              }

              # Home manager configuration
              inputs.home-manager.darwinModules.home-manager
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  backupFileExtension = "bak";
                  users = lib.genAttrs (usernames hostOpts) (username: {
                    imports = [
                      inputs.sops-nix.homeManagerModules.sops
                      inputs.nix-index-database.homeModules.nix-index
                      inputs.zimfw-nix.homeManagerModules.default
                      inputs.nix-themes.homeManagerModules.default
                    ]
                    ++ defaultHomeManagerModules
                    ++ (hostOpts.users.${username} or [ ]);
                  });
                };
              }

            ];
          };
      in
      lib.mapAttrs mkHost config.darwinHosts;
  };
}
