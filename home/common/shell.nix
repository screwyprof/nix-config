{ pkgs, ... }: {
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "docker" "kubectl" "rust" "golang" ];
      theme = "robbyrussell";
    };

    initExtra = ''
      # Custom ZSH configurations
      setopt AUTO_CD
      setopt EXTENDED_GLOB
      
      # Useful aliases
      alias k="kubectl"
      alias d="docker"
      alias g="git"
      alias c="code"
    '';

    shellAliases = {
      ll = "ls -la";
      ".." = "cd ..";
      "..." = "cd ../..";
      nix-rebuild-mac = "darwin-rebuild switch --flake .#mac";
    };
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
    };
  };
} 