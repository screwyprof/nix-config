{ config, lib, pkgs, ... }: {
  programs = {
    zsh = {
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
          "fzf"
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
          src = ./p10k;
          file = "p10k.zsh";
        }
        {
          name = "zsh-autosuggestions";
          src = pkgs.zsh-autosuggestions;
          file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
        }
        {
          name = "zsh-syntax-highlighting";
          src = pkgs.zsh-syntax-highlighting;
          file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
        }
        {
          name = "fzf-tab";
          src = pkgs.fetchFromGitHub {
            owner = "Aloxaf";
            repo = "fzf-tab";
            rev = "master";
            sha256 = "sha256-gvZp8P3quOtcy1Xtt1LAW1cfZ/zCtnAmnWqcwrKel6w=";
          };
        }
      ];

      initExtra = ''
        # Powerlevel10k instant prompt
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi

        # Terminal configuration
        export TERM=xterm-256color

        # fzf configuration
        source ${pkgs.fzf}/share/fzf/completion.zsh
        source ${pkgs.fzf}/share/fzf/key-bindings.zsh
        
        # Custom ZSH configurations
        setopt AUTO_CD
        setopt EXTENDED_GLOB
        
        # # Use modern CLI tools
        # alias cat='${pkgs.bat}/bin/bat'
        # alias ls='${pkgs.eza}/bin/eza'
        # alias ll='${pkgs.eza}/bin/eza -la'
        # alias tree='${pkgs.eza}/bin/eza --tree'
        # alias diff='${pkgs.delta}/bin/delta'
        # alias du='${pkgs.du-dust}/bin/dust'
        # alias df='${pkgs.duf}/bin/duf'
        # alias top='${pkgs.htop}/bin/htop'
        
        # fzf-tab configuration
        enable-fzf-tab
        # Set fzf-tab options here
        zstyle ':fzf-tab:*' fzf-command fzf
        zstyle ':fzf-tab:*' fzf-flags --height 40%
      '';

      shellAliases = {
        # Modern CLI tool replacements
        cat = "${pkgs.bat}/bin/bat";
        ls = "${pkgs.eza}/bin/eza";
        ll = "${pkgs.eza}/bin/eza -la";
        tree = "${pkgs.eza}/bin/eza --tree";
        diff = "${pkgs.delta}/bin/delta";
        du = "${pkgs.du-dust}/bin/dust";
        df = "${pkgs.duf}/bin/duf";
        top = "${pkgs.htop}/bin/htop";
      } // (if pkgs.stdenv.isDarwin then {
        nix-rebuild-mac = "darwin-rebuild switch --flake \".#mac\"";
      } else {});
    };

    # fzf configuration
    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "${pkgs.fd}/bin/fd --type f";
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
        "--inline-info"
      ];
    };
  };

  # Add required packages
  home.packages = with pkgs; [
    # Modern replacements for traditional tools
    bat         # Better cat
    eza         # Better ls
    delta       # Better diff
    duf         # Better df
    du-dust     # Better du
    htop        # Better top
    ripgrep     # Better grep
    fd          # Better find
    fzf         # Fuzzy finder
  ];
} 