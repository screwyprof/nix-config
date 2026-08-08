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
  flake.lib.nativeProjectHome =
    {
      project,
      projectExtensionsDir ? null,
    }:
    (config.flake.homeConfigurations."devbox-host".extendModules {
      modules = [
        {
          home.homeDirectory = lib.mkForce "/work/projects/${project}/home";

          # STAYS OFF, and that is the point rather than an oversight. It would place `base ++ rust` from
          # THIS repo's catalog — right for a Rust project, wrong for a Go one, and wrong in principle:
          # a project declares its own set and devbox realises it. This flag is nix-config choosing for
          # someone else's project, which is the thing screwyprof/devbox#460 exists to stop.
          _module.args.placeVscodeExtensions = false;

          # The project's own set, as a realised STORE PATH — the same seam `devbox-cage` has (decision
          # 009), for the same trust reason, with the same guard. See 009 for the measurements; the two
          # must not drift.
          assertions = [
            {
              assertion =
                projectExtensionsDir == null || builtins.dirOf (toString projectExtensionsDir) == builtins.storeDir;
              message = ''
                projectExtensionsDir must be a store OUTPUT — exactly one component under
                ${builtins.storeDir} — realised by the caller before it gets here.
                Got: ${toString projectExtensionsDir}
              '';
            }
          ];

          # PRECONDITION, identical to the cage's: nothing may already exist at this path. A native project
          # that has been opened has a REAL DIRECTORY there, placed by devbox, and `checkLinkTargets`
          # aborts the whole activation on it. Measured against this very generation — see 009 and
          # screwyprof/devbox#490.
          #
          # NOTHING CLEARS IT YET, deliberately. `nix-rebuild-native` passes no path, so this arg is inert
          # and the collision cannot arise; a clearing step landed here now would strip a project's
          # extensions and put nothing back. It travels with the caller.
          home.file = lib.optionalAttrs (projectExtensionsDir != null) {
            ".vscode-server/extensions".source = "${projectExtensionsDir}/share/vscode/extensions";
          };
        }
      ];
    }).activationPackage;
}
