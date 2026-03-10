{
  flake.modules.homeManager.core-safe-rm =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.safe-rm ];
    };
}
