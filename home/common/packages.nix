{ pkgs, ... }: {
  home.packages = with pkgs; [
    # CLI utilities
    tree
    ripgrep
    fd
    jq
    yq
    curl
    wget
    
    # User-level tools
    k9s  # K8s TUI
  ];
} 