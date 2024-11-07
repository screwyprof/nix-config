{ pkgs, lib, ... }: {
  # Base system packages that should be available on all platforms
  environment.systemPackages = with pkgs; [
    # Basic system utilities
    vim
    git
    
    # Cross-platform applications
    vscode
  ];
} 