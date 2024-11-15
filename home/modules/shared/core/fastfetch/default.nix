{ pkgs, lib, ... }: {
  home.packages = with pkgs; [
    fastfetch
  ];

  # TODO: Use xdg.configFile once fastfetch supports it
  # xdg.configFile = {
  #   "fastfetch/config.jsonc".source = ./config.jsonc;
  #   "fastfetch/gopher.ascii".source = ./gopher.ascii;
  # };

  xdg.configFile."fastfetch/config.jsonc".source = ./config.jsonc;

  # Create actual logo file as fastfech doesn't follow symlynks
  # Gopher logo borrowed from:
  #   https://gist.githubusercontent.com/belbomemo/b5e7dad10fa567a5fe8a/raw/4ed0c8a82a8d1b836e2de16a597afca714a36606/gistfile1.txt
  home.activation.copyFastfetchLogo = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD rm -f ~/.config/fastfetch/gopher.ascii
    $DRY_RUN_CMD mkdir -p ~/.config/fastfetch
    $DRY_RUN_CMD cp ${./gopher.ascii} ~/.config/fastfetch/gopher.ascii
    $DRY_RUN_CMD chmod 644 ~/.config/fastfetch/gopher.ascii
  '';
}
