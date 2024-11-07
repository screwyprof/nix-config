{ pkgs, ... }: {
  home.stateVersion = "23.05";
  programs.home-manager.enable = true;

  imports = [
    ../common/development.nix
    ../common/shell.nix
    ../common/git.nix
  ];

  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    yq
    curl
    wget
    
    go
    rustup
    nodejs
    yarn
    
    docker
    kubectl
    k9s
  ];
} 