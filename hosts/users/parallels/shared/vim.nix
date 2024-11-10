{ pkgs, ... }: {
  programs.vim = {
    enable = true;
    defaultEditor = true;
    packageConfigurable = pkgs.vim_configurable;

    settings = {
      background = "dark";
      mouse = "a";
      number = true;
    };

    plugins = with pkgs.vimPlugins; [
      # Theme
      dracula-vim

      # Status line
      vim-airline
      vim-airline-themes
    ];

    extraConfig = ''
    #   " Print debugging information
    #   function! PrintDebugInfo()
    #     echo "Config file: " . $MYVIMRC
    #     echo "Vim path: " . $VIM
    #     echo "Vim runtime path: " . $VIMRUNTIME
    #   endfunction

    #   " Call debug function on startup
    #   autocmd VimEnter * call PrintDebugInfo()

      set nocompatible
      filetype off
      filetype plugin indent on
      
      syntax on
      colorscheme dracula
      
      set t_Co=256
      set noshowmode
      set backspace=indent,eol,start
      
      " Airline configuration
      let g:airline_theme='luna'
      let g:airline_powerline_fonts = 1
    '';
  };
}
