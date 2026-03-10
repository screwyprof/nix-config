{
  flake.modules.homeManager.core-vim =
    { pkgs, lib, ... }:
    {
      home.activation.vimDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p ~/.vim/{backup,swap,undo}
      '';

      programs.vim = {
        enable = true;
        defaultEditor = true;
        packageConfigurable = pkgs.vim-full;

        settings = {
          background = "dark";
          number = true;
          relativenumber = false;
          expandtab = true;
          shiftwidth = 2;
          tabstop = 2;
          copyindent = true;
          ignorecase = true;
          smartcase = true;
          history = 1000;
          backupdir = [ "~/.vim/backup" ];
          directory = [ "~/.vim/swap" ];
          undodir = [ "~/.vim/undo" ];
        };

        plugins = with pkgs.vimPlugins; [
          dracula-vim
          vim-airline
          vim-airline-themes
        ];

        extraConfig = ''
          syntax on
          set t_Co=256
          set noshowmode
          set backspace=indent,eol,start

          colorscheme dracula

          " Airline configuration
          let g:airline_theme='deus'
          let g:airline_powerline_fonts = 1
        '';
      };
    };
}
