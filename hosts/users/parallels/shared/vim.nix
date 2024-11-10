{ pkgs, lib, ... }: {
  programs.vim = {
    enable = true;
    defaultEditor = true;
    packageConfigurable = pkgs.vim_configurable;

    settings = {
      # Display
      background = "dark"; # "dark" or "light"
      number = true; # Show line numbers
      relativenumber = false; # Relative line numbers

      # Mouse settings
      mouse = "a"; # "n","v","i","c","h","a","r"
      mousefocus = true; # Focus follows mouse
      mousehide = true; # Hide mouse while typing
      mousemodel = "popup"; # "extend","popup","popup_setpos"

      # Indentation
      expandtab = true; # Use spaces instead of tabs
      shiftwidth = 2; # Indentation width
      tabstop = 2; # Tab width
      copyindent = true; # Copy indent structure

      # Search
      ignorecase = true; # Case-insensitive search
      smartcase = true; # Case-sensitive if uppercase present

      # File handling
      hidden = true; # Allow hidden buffers
      modeline = true; # Enable modeline
      undofile = true; # Persistent undo

      # History
      history = 1000; # Command history size

      # Directories
      backupdir = [ "~/.vim/backup" ];
      directory = [ "~/.vim/swap" ];
      undodir = [ "~/.vim/undo" ];
    };

    plugins = with pkgs.vimPlugins; [
      dracula-vim
      vim-airline
      vim-airline-themes
      fzf-vim
    ];

    extraConfig = ''
      syntax on
      set t_Co=256
      set noshowmode
      set backspace=indent,eol,start
      
      colorscheme dracula
      
      " Airline configuration
      let g:airline_theme='luna'
      let g:airline_powerline_fonts = 1

      " Use ripgrep for grep if available
      if executable('rg')
        set grepprg=${pkgs.ripgrep}/bin/rg\ --vimgrep\ --no-heading
        set grepformat=%f:%l:%c:%m
      endif

      " FZF configuration
      " Use fd for file finding
      let $FZF_DEFAULT_COMMAND = '${pkgs.fd}/bin/fd --type f'
      
      " FZF key bindings
      nnoremap <C-p> :Files<CR>
      nnoremap <C-g> :Rg<CR>
      
      " Use bat for FZF preview
      let g:fzf_preview_command = '${pkgs.bat}/bin/bat --style=numbers --color=always {}'
      
      " Delta for git diff
      if executable('delta')
        set diffexpr=DeltaDiff()
        function! DeltaDiff()
          let opt = ""
          if &diffopt =~ "iwhite"
            let opt = opt . "-w "
          endif
          silent execute "!${pkgs.delta}/bin/delta " . opt . v:fname_in . " " . v:fname_new . " > " . v:fname_out
        endfunction
      endif
    '';
  };

  # Create directories with proper permissions
  home.activation.vimDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/.vim/{backup,swap,undo}
  '';
}
