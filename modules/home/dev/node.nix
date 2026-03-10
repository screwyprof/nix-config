{
  flake.modules.homeManager.dev-node = {
    home = {
      sessionPath = [ "$PNPM_HOME" ];
      sessionVariables.PNPM_HOME = "$HOME/Library/pnpm";
    };
  };
}
