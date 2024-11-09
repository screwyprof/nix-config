{ pkgs, lib, ... }: {
  # Base system packages that should be available on all platforms
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    jq
    yq
  ];
} 