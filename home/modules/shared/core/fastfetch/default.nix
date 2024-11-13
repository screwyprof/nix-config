{ pkgs, config, lib, ... }: {
  home.packages = with pkgs; [
    fastfetch
  ];

  xdg.configFile."fastfetch/config.jsonc".source = ./config.jsonc;

  # Create actual file during activation, handling permissions and idempotency
  home.activation.copyFastfetchLogo = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD rm -f ~/.config/fastfetch/gopher.ascii
    $DRY_RUN_CMD mkdir -p ~/.config/fastfetch
    $DRY_RUN_CMD cp ${./gopher.ascii} ~/.config/fastfetch/gopher.ascii
    $DRY_RUN_CMD chmod 644 ~/.config/fastfetch/gopher.ascii
  '';
}
