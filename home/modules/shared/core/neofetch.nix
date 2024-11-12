{ pkgs, config, ... }: {
  home.packages = with pkgs; [
    neofetch
  ];

  xdg.configFile."neofetch/config.conf".text = ''
    print_info() {
        info title
        info underline
        
        prin "$(color 2)╭──────────── Hardware ────────────"
        info "󰌢 " model
        info "󰍛 " cpu
        info "󰑭 " gpu
        info " " memory
        info "󱊡 " resolution
        info "󰋊 " battery
        
        prin "$(color 2)╭──────────── Software ────────────"
        info "󰀵 " distro
        info " " kernel
        info "󰏖 " packages
        info "󰆍 " shell
        info "󰨇 " de
        info "󱂬 " term
        info "󰊠 " term_font
        
        prin "$(color 2)╭──────────── System ─────────────"
        info "󰅐 " uptime
        info "󱈑 " cpu_usage
        info " " disk
        
        prin "$(color 2)───────────────────────────────────"
    }
    
    # Colors
    colors=(2 2 2 2 2 7) # Light green for most items, white for the last
    
    # Text Options
    bold="on"
    underline_enabled="on"
    underline_char="-"
    separator=" ▐ "
    
    # CPU
    cpu_brand="on"
    cpu_speed="on"
    cpu_cores="logical"
    cpu_temp="C"
    
    # GPU
    gpu_brand="on"
    gpu_type="all"
    
    # Memory
    memory_percent="on"
    memory_unit="gib"
    
    # Packages
    package_managers="on"
    
    # Shell
    shell_path="off"
    shell_version="on"
    
    # Disk
    disk_show=('/' '/nix')
    disk_subtitle="mount"
    
    # Backend Settings
    image_backend="ascii"
    ascii_distro="Darwin"  # This will use the built-in Apple logo
    ascii_colors=(2 2 2 2 2 7)  # Green colors for the Apple logo
    ascii_bold="on"
  '';
}
