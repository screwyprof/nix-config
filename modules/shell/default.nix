{ config, lib, pkgs, ... }: {
  home = {
    sessionVariables = {
      POWERLEVEL9K_INSTANT_PROMPT = "quiet";
      TERM = "xterm-256color";

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

      initExtraFirst = ''
        # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi

        export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh
      '';

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
          "aws"
          "cabal"
          "gcloud"
          "golang"
          "grc"
          "kubectl"
          "npm"
          "nvm"
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
        # Terminal configuration
        export TERM=xterm-256color
        
        # Custom ZSH configurations
        setopt AUTO_CD
        setopt EXTENDED_GLOB

        # History settings
        HISTSIZE=50000
        SAVEHIST=50000
        setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
        setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
        setopt SHARE_HISTORY             # Share history between all sessions.
        setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
        setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
        setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
        setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
        setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
        setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
        setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.

        
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

        # Enable command correction
        #setopt CORRECT
        #setopt CORRECT_ALL
        
        # Configure correction prompt
        #SPROMPT="Correct %R to %r? [Yes, No, Abort, Edit] "
        
        # Initialize thefuck
        eval "$(thefuck --alias)"
        # Optional: add shorter alias
        eval "$(thefuck --alias f)"

        # Enable FZF integration for cheat
        export CHEAT_USE_FZF=true
      '';

      shellAliases = {
        # Modern CLI tool replacements
        ls = "${pkgs.eza}/bin/eza";
        ll = "${pkgs.eza}/bin/eza -la";
        tree = "${pkgs.eza}/bin/eza --tree";
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
        nix-rebuild-host = "nixpkgs-fmt . && nix flake check && darwin-rebuild switch --flake '.#macbook'";
        nix-rebuild-mac = "nixpkgs-fmt . && nix flake check && darwin-rebuild switch --flake '.#parallels'";
      } else { });
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
    coreutils # Basic file, shell and text manipulation utilities
    findutils # GNU find, locate, updatedb, and xargs
    gnugrep # GNU grep, egrep, and fgrep
    gnused # GNU sed
    gnutar # GNU tar
    gawk # GNU awk
    gnutls # GNU TLS library
    gnumake # GNU make

    # Modern replacements for traditional tools
    procs # Modern process viewer (ps replacement)
    eza # Better ls
    duf # Better df
    du-dust # Better du
    htop # Better top
    ripgrep # Better grep
    fd # Better find
    fzf # Fuzzy finder
    thefuck # Command correction
  ];
}
