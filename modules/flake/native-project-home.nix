# A home at an ARBITRARY PATH on the host. Its own file so `flake.lib` and `flake.homeConfigurations` are
# not interleaved under one `flake` key, which statix flags.
{ config, lib, ... }:
{
  # The operator's own environment, relocated — derived from `devbox-host` so it IS that environment
  # rather than a second copy of it. Only `homeDirectory` moves.
  #
  # PARAMETERISED BY PATH, NOT BY PROJECT, and that is the whole point of this file. It used to take
  # `{ project }` and compute `/work/projects/${project}/home`, which put a consumer's directory layout
  # inside this repo — and that consumer resolves the layout through its own settings chain
  # (`DEVBOX_PROJECTS_DIR` is a BASE; projects live at `<base>/projects`; unset means somewhere else
  # entirely), so the literal was a DEFAULT written down as a fact. Point that setting elsewhere and this
  # built a home at a path that does not exist. The caller already knows the path: an occupant has it in
  # `$HOME`, an operator types it.
  #
  # It also removes the only reason this repo shelled out to another tool to ask where a directory was.
  #
  # Parameterised at all because `home-files` is NOT relocatable: `.zshenv`, `.config/zsh/{.zshenv,.zshrc,
  # .zimrc}` bake the home path, so reusing the login generation points ZDOTDIR, HISTFILE and the
  # completion cache back at `/home/happygopher.guest`. Verified by building both and diffing.
  #
  # THE CONFIG, so a caller can extend it further — that is what lets a home be composed with something
  # else without this repo knowing what the something else is.
  #
  # `placeVscodeExtensions = false` lives HERE, not in the caller: `devbox-host` places the operator's own
  # `base ++ rust` pick for their LOGIN home, which is right for a Rust repo and wrong for a Go one. A
  # relocated home must never inherit it — whoever owns that home declares what it needs.
  flake.lib.homeAtConfig =
    { homeDirectory }:
    config.flake.homeConfigurations."devbox-host".extendModules {
      modules = [
        {
          _module.args.placeVscodeExtensions = false;
          imports = with config.flake.modules.homeManager; [
            editors-vscode
            happygopher-vscode-taste
          ];
        }
        (
          { lib, ... }:
          {
            home.homeDirectory = lib.mkForce homeDirectory;
          }
        )
      ];
    };

  # The activation package, for a caller that wants to build and run it rather than extend it.
  flake.lib.homeAt =
    { homeDirectory }: (config.flake.lib.homeAtConfig { inherit homeDirectory; }).activationPackage;
}
