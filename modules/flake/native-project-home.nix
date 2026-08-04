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
}
