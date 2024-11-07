{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Core system utilities only
    vim
    git

    # System-level development tools
    docker 
    kubectl 
  ];
} 