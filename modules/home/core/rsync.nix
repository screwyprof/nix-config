{
  flake.modules.homeManager.core-rsync =
    { pkgs, ... }:
    {
      # macOS ships an ancient rsync (2.6.9, frozen for GPL reasons); install a
      # modern rsync so it shadows the outdated system binary.
      home.packages = [ pkgs.rsync ];
    };
}
