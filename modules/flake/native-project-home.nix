# A NATIVE devbox project's home. Its own file so `flake.lib` and `flake.homeConfigurations` are not
# interleaved under one `flake` key, which statix flags.
{ config, lib, ... }:
{
  # A NATIVE project's home, derived from `devbox-host` so it IS the operator's environment rather
  # than a second copy of it — only `homeDirectory` moves.
  #
  # Parameterised because `home-files` is NOT relocatable: `.zshenv`, `.config/zsh/{.zshenv,.zshrc,.zimrc}`
  # bake the home path, so reusing the login generation points ZDOTDIR, HISTFILE and the completion
  # cache back at `/home/happygopher.guest`. Verified by building both and diffing.
  #
  # A FUNCTION, not an attrset of configurations: the set of native projects is runtime state on the
  # node, not something this flake can enumerate. `nix-rebuild-native` applies it per project.
  #
  # NAMED arguments rather than a bare `project:` string, because there are now two of them and the second
  # is optional. The old positional form has one caller, `nix-rebuild-native`, updated with it.
  # The CONFIG, so a caller can extend it further. `nativeProjectHome` below stays the
  # activationPackage wrapper `nix-rebuild-native` already calls.
  #
  # `placeVscodeExtensions = false` lives HERE, not in the caller: `devbox-host` places the operator's
  # own `base ++ rust` pick for their LOGIN home, which is right for a Rust repo and wrong for a Go one.
  # A project home must never inherit it — the project declares what the repo is written in.
  flake.lib.nativeProjectHomeConfig =
    project:
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
            home.homeDirectory = lib.mkForce "/work/projects/${project}/home";
          }
        )
      ];
    };

  flake.lib.nativeProjectHome =
    { project }:
    (config.flake.lib.nativeProjectHomeConfig project).activationPackage;
}
