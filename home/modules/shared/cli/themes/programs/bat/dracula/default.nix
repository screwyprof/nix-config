{ config, lib, ... }:
let
  theme = "base24_dracula";
  themeFileName = "${theme}.tmTheme";
in
{
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
}
