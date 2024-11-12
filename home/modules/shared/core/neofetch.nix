{ pkgs, config, ... }: {
  home.packages = with pkgs; [
    neofetch
  ];

  xdg.configFile."neofetch/config.conf".text = ''
    print_info() {
        info title
        info underline
        
        prin "$(color 4)╭──────────── Hardware ────────────"
        info "󰌢 " model
        info "󰍛 " cpu
        info "󰑭 " gpu
        info " " memory
        info "󱊡 " resolution
        info "󰋊 " battery
        
        prin "$(color 4)╭──────────── Software ────────────"
        info "󰀵 " distro
        info " " kernel
        info "󰏖 " packages
        info "󰆍 " shell
        info "󰨇 " de
        info "󱂬 " term
        info "󰊠 " term_font
        
        prin "$(color 4)╭──────────── System ─────────────"
        info "󰅐 " uptime
        info "󱈑 " cpu_usage
        info " " disk
        
        prin "$(color 4)───────────────────────────────────"
    }

    # Colors
    colors=(4 6 1 8 8 6) # Blue, Cyan, Red, Gray
    
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
    
    # Text Colors
    # Colors for custom colorblocks
    magenta="\033[1;35m"
    green="\033[1;32m"
    white="\033[1;37m"
    blue="\033[1;34m"
    red="\033[1;31m"
    black="\033[1;40;30m"
    yellow="\033[1;33m"
    cyan="\033[1;36m"
    reset="\033[0m"
    bgyellow="\033[1;43;33m"
    bgwhite="\033[1;47;37m"
    cl0="${reset}"
    cl1="${magenta}"
    cl2="${green}"
    cl3="${white}"
    cl4="${blue}"
    cl5="${red}"
    cl6="${yellow}"
    cl7="${cyan}"
    cl8="${black}"
    cl9="${bgyellow}"
    cl10="${bgwhite}"
    
    # Backend Settings
    image_backend="ascii"
    image_source="${config.home.homeDirectory}/.config/neofetch/apple.txt"
    ascii_distro="auto"
    ascii_colors=(4 6 1 8 8 6)
    ascii_bold="on"
  '';

  # Custom Apple ASCII art
  xdg.configFile."neofetch/apple.txt".text = ''
                     'c.
                  ,xNMM.          
                .OMMMMo           
                OMMM0,            
      .;loddo:' loolloddol;.     
    cKMMMMMMMMMMNWMMMMMMMMMM0:   
  .KMMMMMMMMMMMMMMMMMMMMMMMWd.   
  XMMMMMMMMMMMMMMMMMMMMMMMX.     
 ;MMMMMMMMMMMMMMMMMMMMMMMM:      
 :MMMMMMMMMMMMMMMMMMMMMMMM:      
 .MMMMMMMMMMMM
  '';
}
