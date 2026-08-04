{
  config,
  inputs,
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
