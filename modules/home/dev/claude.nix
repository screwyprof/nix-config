{
  flake.modules.homeManager.dev-claude =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      # The OAuth token reaches `claude` and its children only, never the login environment. A token
      # already in the environment (a devcontainer, a `dev claude` shell) wins.
      #
      # Plugin hooks (ponytail) run `node`; claude-code itself is a native Bun binary and brings none.
      # Appended, not prepended: a project's own node (direnv) stays first.
      claude = pkgs.writeShellScriptBin "claude" ''
        if [ -z "''${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
          CLAUDE_CODE_OAUTH_TOKEN="$(<${config.sops.secrets.claude_oauth_token.path})"
          export CLAUDE_CODE_OAUTH_TOKEN
        fi
        PATH="$PATH:${pkgs.nodejs-slim}/bin" exec ${pkgs.claude-code}/bin/claude "$@"
      '';
    in
    {
      sops.secrets.claude_oauth_token = {
        key = "anthropic/oath2_token";
        mode = "0400";
      };

      home = {
        packages = [ claude ];
        sessionPath = [ "$HOME/.local/bin" ];
        activation.claudeStableLink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p $HOME/.local/bin
          rm -f $HOME/.local/bin/claude
          ln -s ${claude}/bin/claude $HOME/.local/bin/claude
        '';
      };
    };
}
