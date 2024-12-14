{ config, pkgs, ... }: {
  imports = [
    ./terminal
    ./preferences
  ];

  home = {
    stateVersion = "24.11";

    # Darwin-specific packages
    packages = with pkgs; [
      mysides
    ];

    # Add activation script for Cursor setup
    # A cludgy way to get ripgrep working in Cursor via remote ssh
    # activation = {
    #   cursorSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    #     run mkdir -p "$HOME/.cursor-server/cli/servers/Stable-b1e87884330fc271d5eb589e368c35f14e76dec0/server/node_modules/@vscode/ripgrep/bin"
    #     run ln -sf ${pkgs.ripgrep}/bin/rg "$HOME/.cursor-server/cli/servers/Stable-b1e87884330fc271d5eb589e368c35f14e76dec0/server/node_modules/@vscode/ripgrep/bin/rgArm"
    #   '';
    # };
  };

  xdg.dataHome = "${config.home.homeDirectory}/.local/share";
}
