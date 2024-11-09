{ pkgs, ... }: {
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
    "editor.fontSize" = 18;
      "editor.fontFamily" = "'JetBrainsMono', 'FiraCode Nerd Font', monospace";
      "editor.fontLigatures" = true;

      "terminal.integrated.fontSize" = 18;
      "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font'";

      "update.mode" = "none";
      "extensions.autoUpdate" = false;
    };
  };
} 