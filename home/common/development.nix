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
    package = pkgs.vscode;
    mutableExtensionsDir = false;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    extensions = with pkgs.vscode-extensions; [
      rust-lang.rust-analyzer
      golang.go
    ];
    userSettings = {
      "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'FiraCode Nerd Font', monospace";
      "editor.fontLigatures" = true;
      "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font'";
      "editor.fontSize" = 14;
      "terminal.integrated.fontSize" = 14;
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