{
  flake.modules.homeManager.cli-jq =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.jq ];
    };
}
