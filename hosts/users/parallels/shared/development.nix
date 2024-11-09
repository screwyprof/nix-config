{ pkgs, ... }: {
  # Development tools
  home.packages = with pkgs; [
    #go
    #rustup
    #nodejs
    #yarn
    #pnpm
    #nvm

    # Add Nix development tools
    nixpkgs-fmt
    nix-prefetch-github
    nix-prefetch-git

    # Additional tools
    #docker
    #docker-compose
    #kubectl
    #kubectx
    #k9s
  ];

  # IDE configurations
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = false;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    extensions = with pkgs.vscode-extensions; [
      rust-lang.rust-analyzer
      golang.go
    ];
    userSettings = {
      "editor.fontFamily" = "'JetBrainsMono', 'FiraCode Nerd Font', monospace";
      "editor.fontLigatures" = true;
      "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font'";
      "editor.fontSize" = 18;
      "terminal.integrated.fontSize" = 18;
      "update.mode" = "none";
      "extensions.autoUpdate" = false;
    };
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
    AWS_PROFILE = "codefi";
    CARGO_NET_GIT_FETCH_WITH_CLI = "true";
    POWERLEVEL9K_INSTANT_PROMPT = "quiet";
  };
} 