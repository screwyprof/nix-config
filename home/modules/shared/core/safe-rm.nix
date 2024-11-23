{ pkgs, ... }: {
  home.packages = with pkgs; [
    safe-rm
  ];
}
