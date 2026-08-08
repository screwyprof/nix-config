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

      config.home.file =
        lib.optionalAttrs (cfg.extensions != [ ]) (mkServerExtensions {
          inherit pkgs;
          exts = cfg.extensions;
        })
        // lib.optionalAttrs (cfg.settings != { }) {
          ".vscode-server/data/Machine/settings.json".text = builtins.toJSON cfg.settings;
        };
    };
}
