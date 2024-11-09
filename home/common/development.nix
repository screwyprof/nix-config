{ pkgs, ... }: {
  # Development tools
  home.packages = with pkgs; [
    go
    rustup
    nodejs
    yarn

    # Add Nix development tools
    nixpkgs-fmt
    nix-prefetch-github
    nix-prefetch-git
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
  home.sessionVariables = {
    EDITOR = "vim";
    VISUAL = "code";
    GOPATH = "$HOME/go";
    PATH = "$PATH:$GOPATH/bin";
  };
} 