{ pkgs, ... }: {
  home.packages = with pkgs; [
    neofetch
  ];

  xdg.configFile = {
    "neofetch/config.conf".source = ./config.conf;
    "neofetch/gopher.ascii".source = ./gopher.ascii;
  };
}
