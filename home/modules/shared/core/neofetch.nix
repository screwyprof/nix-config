{ pkgs, config, ... }: {
  home.packages = with pkgs; [
    neofetch
  ];

  # First create the gopher ASCII art file
  xdg.configFile."neofetch/gopher.txt".text = ''
             ,_---~~~~~----._         
      _,,_,*^____      _____``*g*\"*, 
     / __/ /'     ^.  /      \ ^@q   f 
    [  @f | @))    |  | @))   l  0 _/  
     \`/   \~____ / __ \_____/    \   
      |           _l__l_           I   
      }          [______]           I  
      ]            | | |            |  
      ]             ~ ~             |  
      |                            |   
       |                           |   
  '';

  # Then reference it in the config
  xdg.configFile."neofetch/config.conf".text = ''
    print_info() {
        prin "$(color 4)"
     
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
        prin "$(color 4)󰋊 Disk   " "$(df -h / | awk 'NR==2 {printf "%s used of %s (%s)", $3, $2, $5}')"
        prin "$(color 4)󰅐 Uptime " "$(uptime | cut -d',' -f1 | awk '{split($3,a,":"); if (a[1] >= 24) printf "%d days, %d hours, %d mins", a[1]/24, a[1]%24, a[2]; else if (a[1] > 0) printf "%d hours, %d mins", a[1], a[2]; else printf "%d mins", a[2]}')"
        prin "$(color 4)───────────────────────────────────"
    }
    
    # Colors
    colors=(4 4 4 4 4 7)
    
    # Backend Settings
    image_backend="ascii"
    image_source="${config.xdg.configHome}/neofetch/gopher.txt"
    ascii_distro="none"
    ascii_colors=(4 4 4 4 4 7)
    ascii_bold="on"
  '';
}
