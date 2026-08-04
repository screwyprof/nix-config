{
  config,
  inputs,
  lib,
  self,
  ...
}:
{
  # STANDALONE targets: neither surface has a host configuration here to hang `home-manager.users` off
  # — the node's NixOS config lives in the devbox repo, and a cage's closure is built by devbox — so
  # each home is built and activated on its own.
  flake.homeConfigurations."devbox-cage" = inputs.home-manager.lib.homeManagerConfiguration {
    # The repo's own pkgs assembly: the cli modules reference `zim-plugins` from `flake.overlays.default`.
    pkgs = import inputs.nixpkgs {
      system = "aarch64-linux";
      overlays = [ self.overlays.default ];
      config.allowUnfree = true;
    };
    modules = [
      # Same option-providing modules the darwin host injects: zimfw-nix DEFINES the `programs.zsh.zimfw`
      # options the cli modules set, and nix-themes supplies the p10k zmodules and config.
      inputs.zimfw-nix.homeManagerModules.default
      inputs.nix-themes.homeManagerModules.default
      config.flake.modules.homeManager.devbox-cage
    ];
  };

  # A NATIVE project's home, derived from `devbox-host` so it IS the operator's environment rather
  # than a second copy of it — only `homeDirectory` moves.
  #
  # Parameterised because `home-files` is NOT relocatable: `.zshenv`, `.config/zsh/{.zshenv,.zshrc,.zimrc}`
  # bake the home path, so reusing the login generation points ZDOTDIR, HISTFILE and the completion
  # cache back at `/home/happygopher.guest`. Verified by building both and diffing.
  #
  # A FUNCTION, not an attrset of configurations: the set of native projects is runtime state on the
  # node, not something this flake can enumerate. `nix-rebuild-native` applies it per project.
  flake.lib.nativeProjectHome =
    project:
    (config.flake.homeConfigurations."devbox-host".extendModules {
      modules = [
        {
          home.homeDirectory = lib.mkForce "/work/projects/${project}/home";
          # devbox owns `.vscode-server/extensions` for a project; the server+CLI pin stays.
          _module.args.placeVscodeExtensions = false;
        }
      ];
    }).activationPackage;

  # The node's own home.
  flake.homeConfigurations."devbox-host" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "aarch64-linux";
      overlays = [ self.overlays.default ];
      config.allowUnfree = true;
    };
    modules = [
      inputs.zimfw-nix.homeManagerModules.default
      # The PROMPT lives here, not in `cli-zsh`: nix-themes supplies the powerlevel10k zmodules and the
      # p10k config file (pkgs/nix-themes/programs/zsh). `cli-zsh` has those lines commented out, so
      # without this module you get zsh, zim and completions — but a default prompt.
      inputs.nix-themes.homeManagerModules.default
      config.flake.modules.homeManager.devbox-host
    ];
  };
}
