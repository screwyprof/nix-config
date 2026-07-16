{
  flake.modules.homeManager.dev-node =
    { config, ... }:
    {
      home = {
        sessionPath = [ "$PNPM_HOME" ];
        # XDG-consistent global dir; overrides pnpm's macOS default (~/Library/pnpm).
        sessionVariables.PNPM_HOME = "${config.xdg.dataHome}/pnpm";
      };
    };
}
