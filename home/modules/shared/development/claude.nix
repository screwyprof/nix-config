{ config, pkgs, lib, ... }:

{
  home = {
    packages = [
      pkgs.claude-code
    ];

    # Add to PATH
    sessionPath = [ "$HOME/.local/bin" ];

    activation = {
      # Stable binary path to prevent macOS permission resets
      claudeStableLink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p $HOME/.local/bin
        rm -f $HOME/.local/bin/claude
        ln -s ${pkgs.claude-code}/bin/claude $HOME/.local/bin/claude
      '';
    };
  };
}
