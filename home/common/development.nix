{ pkgs, ... }: {
  # Development tools
  home.packages = with pkgs; [
    go
    rustup
    nodejs
    yarn
  ];

  # IDE configurations
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      rust-lang.rust-analyzer
      golang.go
      vscodevim.vim
    ];
  };

  # Development environment variables
  home.sessionVariables = {
    EDITOR = "vim";
    VISUAL = "code";
    GOPATH = "$HOME/go";
    PATH = "$PATH:$GOPATH/bin";
  };
} 