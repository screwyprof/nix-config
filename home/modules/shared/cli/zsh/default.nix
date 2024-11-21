{ config, lib, pkgs, ... }:

let
  # Modern CLI replacements
  modernCLI = with pkgs; {
    ls = "${eza}/bin/eza --icons=always";
    ll = "${eza}/bin/eza -la --icons=always";
    tree = "${eza}/bin/eza --tree --all --icons --git-ignore --color=always";
    #du = "${du-dust}/bin/dust";
    #df = "${duf}/bin/duf";
    #top = "${htop}/bin/htop";
  };

  # GNU utils aliases
  gnuUtils = with pkgs; {
    grep = "${gnugrep}/bin/grep --color=auto";
    sed = "${gnused}/bin/sed";
    awk = "${gawk}/bin/awk";
    tar = "${gnutar}/bin/tar";
    make = "${gnumake}/bin/make";
  };
in
{
  imports = [ ./zim ]; # Import Zim module

  home = {
    sessionVariables = {
      NOSYSZSHRC = "1";
      TERM = "xterm-256color";
      K9S_EDITOR = "vim";
      PATH = lib.concatStringsSep ":" [
        "$HOME/.local/bin"
        "${pkgs.coreutils}/bin"
        "${pkgs.findutils}/bin"
        "${pkgs.gnugrep}/bin"
        "${pkgs.gnused}/bin"
        "${pkgs.gnutar}/bin"
        "${pkgs.gawk}/bin"
        "$PATH"
      ];
    };

    packages = with pkgs; [
      procs
      eza
      duf
      du-dust
      htop
      ripgrep
      shellcheck
    ];
  };

  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = false;
    autosuggestion.enable = false;
    enableCompletion = false;

    initExtraFirst = ''
      # Cache directory setup
      zsh_cache="${config.xdg.cacheHome}/zsh"
      mkdir -p "$zsh_cache"

      # Ensure zcompdump uses XDG cache directory
      export ZSH_COMPDUMP="${config.xdg.cacheHome}/zsh/zcompdump-''${ZSH_VERSION}"

      # Zim's completion optimization logic
      if [[ -s "''${ZSH_COMPDUMP}" && (! -s "''${ZSH_COMPDUMP}.zwc" || "''${ZSH_COMPDUMP}" -nt "''${ZSH_COMPDUMP}.zwc") ]]; then
        # If .zwc file is missing or older than .zcompdump, compile it
        zcompile "''${ZSH_COMPDUMP}"
      fi

      # Initialize completion system
      autoload -U compinit 
      if [[ -n ''${XDG_CACHE_HOME}/zsh/zcompdump(#qN.mh+24) ]]; then
        compinit -d "''${ZSH_COMPDUMP}"
      else
        compinit -C -d "''${ZSH_COMPDUMP}"
      fi

      # Add completion styles
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path "$zsh_cache"
      zstyle ':completion:*' completer _complete _match _approximate
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case insensitive
      zstyle ':completion:*' menu select=2 # Show menu after 2 tabs
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS} # Use LS_COLORS
      zstyle ':completion:*' verbose true

      # Group matches
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*:matches' group yes

      # Fuzzy matching of completions
      zstyle ':completion:*:approximate:*' max-errors 1 numeric

      # Don't complete unavailable commands
      zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

      # Array completion element sorting
      zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters
    '';

    history = {
      size = 50000;
      save = 50000;
      path = "$HOME/.zsh_history";
      extended = true;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
      share = true;
    };

    historySubstringSearch.enable = true;
    shellAliases = modernCLI // gnuUtils;

    # Oh-my-zsh with p10k theme
    # oh-my-zsh = {
    #   enable = true;
    #   theme = "powerlevel10k";
    #   custom = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k";
    #   plugins = [
    #     "git"
    #     "gitfast"
    #     "alias-finder"
    #     "command-not-found"
    #     "copyfile"
    #     "direnv"
    #     "dotenv"
    #     "extract"
    #     "aws"
    #     "cabal"
    #     "gcloud"
    #     "golang"
    #     "grc"
    #     "kubectl"
    #     "npm"
    #     "nvm"
    #     "rust"
    #     "sudo"
    #     "yarn"
    #   ] ++ lib.optionals pkgs.stdenv.isDarwin [ "macos" ];
    # };


    #Only load custom p10k config
    plugins = [
      {
        name = "powerlevel10k-config";
        src = ./p10k;
        file = "p10k.zsh";
      }
    ];


    # Initialize p10k instant prompt first
    initExtraBeforeCompInit = ''
      ZSH_DISABLE_COMPFIX=true
    '';

    profileExtra = ''
      # hook in brew
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';

    zimfw = {
      enable = true;
      degit = true;
      zmodules = [
        # Core modules first
        #"environment"
        #"git"
        #"input"
        #"termtitle"
        #"utility"

        # Info modules (need to be before prompt)
        #"git-info"
        #"duration-info"
        #"prompt-pwd"

        # Theme (after all info modules)
        "romkatv/powerlevel10k"

        # Completion modules
        "zsh-users/zsh-completions --fpath src"
        "zimfw/fzf"
        "Aloxaf/fzf-tab"

        # These must be last
        "zsh-users/zsh-syntax-highlighting"
        "zsh-users/zsh-autosuggestions"
      ];

      initAfterZim = ''
        # Cache directory setup
        zsh_cache="${config.xdg.cacheHome}/zsh"
        mkdir -p "$zsh_cache"

        # Initialize completion after Zim loads
        autoload -U compinit && compinit

        # Keep all existing completion styles
        zstyle ':completion:*' use-cache on
      
        # Set completion options
        zstyle ':completion:*' completer _complete _match _approximate
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case insensitive
        #zstyle ':completion:*' menu select=2 # Show menu after 2 tabs
        #zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS} # Use LS_COLORS
        zstyle ':completion:*' verbose true
      
        # Group matches
        zstyle ':completion:*' group-name ""
        zstyle ':completion:*:matches' group yes
      
        # Fuzzy matching of completions
        zstyle ':completion:*:approximate:*' max-errors 1 numeric
      
        # Don't complete unavailable commands
        zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'
      
        # Array completion element sorting
        zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters
      '';
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
