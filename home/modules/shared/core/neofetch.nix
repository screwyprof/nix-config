{ pkgs, config, ... }: {
  # Install neofetch
  home.packages = with pkgs; [
    neofetch
  ];

  # Configure neofetch
  xdg.configFile."neofetch/config.conf".text = ''
    print_info() {
        info title
        info underline
        
        info "OS" distro
        info "Host" model
        info "Kernel" kernel
        info "Uptime" uptime
        info "Packages" packages
        info "Shell" shell
        info "CPU" cpu
        info "Memory" memory
        info "Disk" disk
        info "Battery" battery
        
        info cols
    }
  '';
}
