{ pkgs, config, ... }: {
  home.packages = with pkgs; [
    neofetch
  ];

  xdg.configFile."neofetch/config.conf".text = ''
    print_info() {
        info title
        info underline
        
        prin "$(color 4)╭──────────── Hardware ────────────"
        info "󰟀" model
        prin "$(color 4)󰍛" "$(sysctl -n machdep.cpu.brand_string) ($(sysctl -n hw.ncpu) cores)"
        info "󰘚" memory
        info "󰢮" gpu
        
        prin "$(color 4)╭──────────── Software ────────────"
        info "󰀵" distro
        info "󰒋" kernel
        info "󰏗" packages
        info "󰆍" shell
        info "󰨇" de
        info "󰆍" term
        
        prin "$(color 4)╭──────────── System ─────────────"
        prin "$(color 4)󰋊" "$(df -h / | awk 'NR==2 {printf "%s used of %s (%s)", $3, $2, $5}')"
        prin "$(color 4)󰅐" "$(uptime | cut -d',' -f1 | awk '{split($3,a,":"); if (a[1] >= 24) printf "%d days, %d hours, %d mins", a[1]/24, a[1]%24, a[2]; else if (a[1] > 0) printf "%d hours, %d mins", a[1], a[2]; else printf "%d mins", a[2]}')"
        prin "$(color 4)───────────────────────────────────"
    }
    
    # Colors
    colors=(4 4 4 4 4 7)  # Changed to blue theme
    
    # Text Options
    bold="on"
    underline_enabled="on"
    underline_char="-"
    separator="  "        # Using two spaces for better alignment
    
    # CPU
    cpu_brand="on"
    cpu_speed="on"
    cpu_cores="logical"
    
    # Memory
    memory_percent="on"
    memory_unit="gib"
    
    # Packages
    package_managers="on"
    
    # Shell
    shell_path="off"
    shell_version="on"
    
    # OS Info
    os_arch="on"
    distro_shorthand="on"

    # Backend Settings
    image_backend="ascii"
    ascii_distro="Darwin"
    ascii_colors=(1 2 3 4 5 6)
    ascii_bold="on"
  '';
}
