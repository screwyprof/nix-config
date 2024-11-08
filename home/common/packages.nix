{ pkgs, ... }: {
  home.packages = with pkgs; [    
    # User-level tools
    k9s  # K8s TUI
  ];
} 