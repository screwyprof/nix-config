{ config, pkgs, lib, inputs, ... }:

{
  home = {
    packages = [
      inputs.claude-code.packages.${pkgs.system}.default
    ];

    # Add to PATH
    sessionPath = [ "$HOME/.local/bin" ];

    activation = {
      # Stable binary path to prevent macOS permission resets
      claudeStableLink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p $HOME/.local/bin
        rm -f $HOME/.local/bin/claude
        ln -s ${inputs.claude-code.packages.${pkgs.system}.default}/bin/claude $HOME/.local/bin/claude
      '';

      # Preserve config during switches
      preserveClaudeConfig = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
        [ -f "$HOME/.claude.json" ] && cp -p "$HOME/.claude.json" "$HOME/.claude.json.backup" || true
      '';

      restoreClaudeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        [ -f "$HOME/.claude.json.backup" ] && [ ! -f "$HOME/.claude.json" ] && cp -p "$HOME/.claude.json.backup" "$HOME/.claude.json" || true
      '';
    };
  };
}
