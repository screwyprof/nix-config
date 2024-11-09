{ pkgs, ... }: {

  # Development tools
  home.packages = with pkgs; [
    # Add Nix development tools
    nixpkgs-fmt
    nix-prefetch-github
    nix-prefetch-git

    # Version manager
    asdf-vm
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.zsh = {
    initExtra = ''
      # asdf setup
      . ${pkgs.asdf-vm}/share/asdf-vm/asdf.sh
      
      # Enable completions
      fpath=(${pkgs.asdf-vm}/share/asdf-vm/completions $fpath)
    '';
  };


  # Development environment variables
  home.sessionPath = [
    "$GOPATH/bin"
    "$HOME/.gobrew/current/bin"
    "$HOME/.gobrew/bin"
  ];

  home.sessionVariables = {
    EDITOR = "vim";
    VISUAL = "code";
    GOPATH = "$HOME/go";
    TERM = "xterm-256color";
    K9S_EDITOR = "vim";
    CDPATH = "$CDPATH:$GOPATH/src";
    
    # libpq
    #LDFLAGS = "-L/opt/homebrew/opt/libpq/lib";
    #CPPFLAGS = "-I/opt/homebrew/opt/libpq/include";
    #PKG_CONFIG_PATH = "/opt/homebrew/opt/libpq/lib/pkgconfig";
    #PQ_LIB_DIR = "$(brew --prefix libpq)/lib";
    
    # libclang
    #LDFLAGS = "-L/opt/homebrew/opt/llvm/lib";
    #CPPFLAGS = "-I/opt/homebrew/opt/llvm/include";

    # Add these
    #AWS_PROFILE = "codefi";
    CARGO_NET_GIT_FETCH_WITH_CLI = "true";
  };
} 