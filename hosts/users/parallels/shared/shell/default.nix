{ config, lib, pkgs, ... }: {
  home = {
    sessionVariables = {
      POWERLEVEL9K_INSTANT_PROMPT = "quiet";
      # Prefer GNU versions over BSD ones
      PATH = lib.concatStringsSep ":" [
        "${pkgs.coreutils}/bin"
        "${pkgs.findutils}/bin"
        "${pkgs.gnugrep}/bin"
        "${pkgs.gnused}/bin"
        "${pkgs.gnutar}/bin"
        "${pkgs.gawk}/bin"
        "$PATH"
      ];
    };
  };

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
          "aws"
          "cabal"
          "gcloud"
          "golang"
          "grc"
          "kubectl"
          "npm"
          "nvm"
          "macos"
          "rust"
          "sudo"
          "yarn"
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
        
        # fzf-tab configuration
        enable-fzf-tab
        # Set fzf-tab options here
        zstyle ':fzf-tab:*' fzf-command fzf
        zstyle ':fzf-tab:*' fzf-flags --height 40%
        
        # Docker helpers
        docker-rm-containers() {
          docker stop $(docker ps -aq)
          docker rm $(docker ps -aq)
        }

        docker-rm-all() {
          docker-rm-containers
          docker network prune -f
          docker rmi -f $(docker images --filter dangling=true -qa)
          docker volume rm $(docker volume ls --filter dangling=true -q)
          docker rmi -f $(docker images -qa)
        }
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
        
        # GNU utils aliases
        grep = "${pkgs.gnugrep}/bin/grep --color=auto";
        sed = "${pkgs.gnused}/bin/sed";
        awk = "${pkgs.gawk}/bin/awk";
        tar = "${pkgs.gnutar}/bin/tar";
        make = "${pkgs.gnumake}/bin/make";
        
        # Docker compose aliases
        dcp = "docker-compose pull";
        dcps = "docker-compose ps";
        dcu = "docker-compose up -d";
        dcd = "docker-compose down --remove-orphans --volumes";
        dcr = "docker-compose restart";
        dclf = "docker-compose logs -f";
        dlf = "docker logs -f";
        dcuf = "docker-compose up --build --force-recreate --no-deps -d";
        dcs = "docker-compose stop";
        drac = "docker container prune";
        drav = "docker volume prune";
        dra = "docker system prune --volumes";
        
        # Git aliases
        fakecommit = "git commit --amend --no-edit && git push -f";
        cherrymaster = "git cherry -v master | cut -d ' ' -f3-";
        rmbranches = "git branch | grep -v 'master' | grep -v 'main' | xargs git branch -D";
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
    # GNU Core Utilities
    coreutils    # Basic file, shell and text manipulation utilities
    findutils    # GNU find, locate, updatedb, and xargs
    gnugrep     # GNU grep, egrep, and fgrep
    gnused      # GNU sed
    gnutar      # GNU tar
    gawk        # GNU awk
    gnutls      # GNU TLS library
    gnumake     # GNU make

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