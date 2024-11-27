{ config, lib, ... }:
let
  theme = "base24_dracula";
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
