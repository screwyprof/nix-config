{
  flake.modules.homeManager.cli-eza =
    { lib, pkgs, ... }:
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
          "zimfw/exa"
        ];
      };
    };
}
