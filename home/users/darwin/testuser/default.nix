{ config, lib, pkgs, ... }: {
  imports = [
    #./terminal
    ./preferences
    ../../../modules/shared
  ];

  home = {
    username = "testuser";
    homeDirectory = lib.mkForce "/Users/testuser";
    stateVersion = "24.05";

    # Darwin-specific packages
    packages = with pkgs; [
      mysides
    ];

    # Add activation script for Cursor setup
    activation = {
      cursorSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "$HOME/.cursor-server/cli/servers/Stable-b1e87884330fc271d5eb589e368c35f14e76dec0/server/node_modules/@vscode/ripgrep/bin"
        $DRY_RUN_CMD ln -sf ${pkgs.ripgrep}/bin/rg "$HOME/.cursor-server/cli/servers/Stable-b1e87884330fc271d5eb589e368c35f14e76dec0/server/node_modules/@vscode/ripgrep/bin/rgArm"
      '';
    };
  };

  xdg.dataHome = "${config.home.homeDirectory}/.local/share";
}
