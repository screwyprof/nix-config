{ inputs, self, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
    inputs.pre-commit-hooks.flakeModule
  ];

  perSystem =
    { config, pkgs, ... }:
    {
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
        src = inputs.nix-filter.lib.filter {
          root = self;
          include = [
            (inputs.nix-filter.lib.matchExt "nix")
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
    };
}
