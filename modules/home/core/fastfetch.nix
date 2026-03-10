{
  flake.modules.homeManager.core-fastfetch =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.fastfetch ];

      xdg.configFile = {
        "fastfetch/config.jsonc".source = ./fastfetch-config/config.jsonc;
        "fastfetch/gopher.ascii".source = ./fastfetch-config/gopher.ascii;
      };
    };
}
