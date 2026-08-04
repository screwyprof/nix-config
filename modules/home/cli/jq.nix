# `home.packages`, not `programs.jq`: there is nothing to configure, matching how `cli-bat` adds its
# bat-extras. NOT in the `cli` aggregate — `devbox-host` imports the `cli-*` modules individually, and
# the aggregate has other consumers that have not asked for this.
{
  flake.modules.homeManager.cli-jq =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.jq ];
    };
}
