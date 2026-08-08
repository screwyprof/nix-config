{ config, ... }:
let
  # Captured OUT here: inside the home-manager module below, `config` is the HOME's config, not the
  # flake's, so the renderer is unreachable from there.
  inherit (config.flake.lib.vscode) mkServerExtensions;
in
{
  # The ONE place a home's VS Code extensions and settings are assembled.
  #
  # Both contributors — the operator's taste (this repo) and the project's toolchain (its own flake) —
  # write the SAME options, and the module system merges them. That is forced, not stylistic: a home has
  # one `.vscode-server/extensions` directory and one `Machine/settings.json`, so two renderers cannot
  # coexist; the second would replace the first and you would have to choose taste or toolchain.
  flake.modules.homeManager.editors-vscode =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.editors.vscode;
    in
    {
      options.editors.vscode = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Render the assembled set into this home. **Off by default, and that is a safety gate rather
            than a preference.**

            Every project home that has ever been opened holds a REAL DIRECTORY at
            `.vscode-server/extensions`, placed by devbox. home-manager's `checkLinkTargets` refuses to
            clobber it and `checkNewGenCollision || exit 1` aborts the WHOLE activation, which devbox
            records as a warning — so the home silently stalls on its last generation. `mkServerExtensions`
            says the same thing in its own docstring, and decision 008 says it again.

            Turn on per home only once that directory is gone (screwyprof/devbox#481 reaps them). Until
            then a home that never opts in renders nothing and behaves exactly as before.
          '';
        };

        extensions = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = ''
            VS Code extensions for this home. LISTS MERGE, so the operator adds taste (a theme) and the
            project adds what the repo is written in (its language servers), and both arrive.
          '';
        };

        settings = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
          description = ''
            Remote MACHINE settings — per `$HOME`, which is what discriminates a project (#352).
            Merges per key; use `lib.mkDefault` for anything a project may reasonably override, so the
            project wins on language-shaped keys and the operator wins on taste.
          '';
        };
      };

      config.home.file = lib.mkIf cfg.enable (
        lib.optionalAttrs (cfg.extensions != [ ]) (mkServerExtensions {
          inherit pkgs;
          exts = cfg.extensions;
        })
        // lib.optionalAttrs (cfg.settings != { }) {
          ".vscode-server/data/Machine/settings.json".text = builtins.toJSON cfg.settings;
        }
      );
    };
}
