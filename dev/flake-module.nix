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

      # Every remote home places only `vscodeServerPins` that carry the fleet's (aarch64-linux) hashes, so the
      # Mac's client must be one of those.
      checks.vscode-client-pinned =
        let
          client =
            self.darwinConfigurations.macbook.config.home-manager.users.happygopher.programs.vscode.package;
          placed = builtins.filter (
            pin: pin.hashes ? server-linux-arm64 && pin.hashes ? cli-alpine-arm64
          ) self.lib.vscodeServerPins;
          commits = map (pin: pin.commit) placed;
        in
        if builtins.elem client.rev commits then
          pkgs.runCommand "vscode-client-pinned" { } "touch $out"
        else
          throw "vscode-client-pinned: the Mac's VS Code ${client.version} (${client.rev}) has no hashed pin in vscodeServerPins (modules/home/dev/vscode-remote.nix)";

      devShells.default = pkgs.mkShell {
        buildInputs = [ pkgs.pre-commit ] ++ config.pre-commit.settings.enabledPackages;
        shellHook = config.pre-commit.installationScript;
      };
    };
}
