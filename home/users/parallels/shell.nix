{ config, lib, pkgs, ... }: {
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "gitfast"
        "alias-finder"
        "command-not-found"
        "copyfile"
        "direnv"
        "dotenv"
        "extract"
      ] ++ lib.optionals pkgs.stdenv.isDarwin [
        "macos"
      ];
      custom = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k";
      theme = "powerlevel10k";
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = ./p10k-config;
        file = "p10k.zsh";
      }
    ];

    initExtra = ''
      # Powerlevel10k instant prompt
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      # Custom ZSH configurations
      setopt AUTO_CD
      setopt EXTENDED_GLOB
    '' + lib.optionalString pkgs.stdenv.isDarwin ''
      # macOS specific configurations
      export TERM=xterm-256color
    '';

    shellAliases = {
      # Basic
      ll = "ls -la";
      ".." = "cd ..";
      "..." = "cd ../..";
    } // lib.optionalAttrs pkgs.stdenv.isDarwin {
      # macOS specific aliases
      nix-rebuild-mac = "darwin-rebuild switch --flake .#mac";
    };
  };
} 