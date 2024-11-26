{ config, lib, ... }:
let
  inherit (config.theme) name spec;
  theme = "${spec}_${name}";
  themeFileName = "${theme}.tmTheme";
in
{
  config = lib.mkIf config.programs.bat.enable {
    programs = {
      bat = {
        config.theme = lib.mkForce theme;

        themes = {
          "${theme}" = {
            src = ./.;
            file = themeFileName;
          };
        };
      };
    };
  };
}
