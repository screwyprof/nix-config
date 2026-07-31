{
  config,
  inputs,
  self,
  ...
}:
{
  # STANDALONE home-manager targets — for homes that have no host configuration in this repo.
  #
  # A devbox cage is exactly that: its system closure is built by the devbox repo, and its `/home/dev` is
  # a per-project directory devbox creates. There is no `nixosConfigurations.<cage>` here to hang
  # `home-manager.users` off, so the home is built and activated on its own:
  #
  #   nix build  .#homeConfigurations.devbox-cage.activationPackage
  #   <result>/activate                                  # run INSIDE the cage, as `dev`
  flake.homeConfigurations."devbox-cage" = inputs.home-manager.lib.homeManagerConfiguration {
    # The repo's OWN pkgs assembly, not raw `legacyPackages`: the cli modules reference `zim-plugins`,
    # which comes from `flake.overlays.default`. Without the overlay the build dies on an undefined
    # variable — the same assembly `perSystem` does for every other output here.
    pkgs = import inputs.nixpkgs {
      system = "aarch64-linux";
      overlays = [ self.overlays.default ];
      config.allowUnfree = true;
    };
    modules = [
      # The same option-providing modules the darwin host injects (see hosts/darwin/shared/builder.nix).
      # They are what DEFINE options the cli modules SET — `cli-bat`/`cli-eza`/`cli-fzf`/`cli-zoxide` all
      # register zsh/zim integration, so without these the build fails on an option that "does not exist".
      inputs.zimfw-nix.homeManagerModules.default
      # The PROMPT lives here, not in `cli-zsh`: nix-themes supplies the powerlevel10k zmodules and the
      # p10k config file (pkgs/nix-themes/programs/zsh). `cli-zsh` has those lines commented out, so
      # without this module you get zsh, zim and completions — but a default prompt.
      inputs.nix-themes.homeManagerModules.default
      config.flake.modules.homeManager.devbox-cage
    ];
  };

  # The operator's home on the devbox NODE. Standalone for the same reason: the node's NixOS config
  # lives in the devbox repo, so there is no `nixosConfigurations.devbox` here to hang it off.
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
