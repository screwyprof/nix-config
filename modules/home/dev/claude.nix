{
  flake.modules.homeManager.dev-claude =
    {
      pkgs,
      lib,
      ...
    }:
    {
      home = {
        packages = [ pkgs.claude-code ];
        sessionPath = [ "$HOME/.local/bin" ];
        activation.claudeStableLink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p $HOME/.local/bin
          rm -f $HOME/.local/bin/claude
          ln -s ${pkgs.claude-code}/bin/claude $HOME/.local/bin/claude
        '';
      };
    };
}
