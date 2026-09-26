{ config, ... }:
let
  inherit (config.flake.lib) zimfwModule;
in
{
  flake.modules.homeManager.cli-eza =
    { lib, pkgs, ... }:
    let
      zim = zimfwModule pkgs;
    in
    {
      home = {
        packages = [ pkgs.eza ];

        sessionVariables = {
          EZA_ICONS_AUTO = "1";
        };
      };

      programs.zsh = {
        shellAliases = {
          tree = "${pkgs.eza}/bin/eza --tree --all --icons --git-ignore --color=always";
        };

        zimfw.zmodules = lib.mkOrder 200 [
          (zim "zimfw/exa")
        ];
      };
    };
}
