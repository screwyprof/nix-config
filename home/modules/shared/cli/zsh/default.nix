{ lib, pkgs, ... }:

let
  # Modern CLI replacements
  modernCLI = with pkgs; {
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

      EZA_ICONS_AUTO = "1";

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
    dotDir = ".config/zsh";
    syntaxHighlighting.enable = false;
    autosuggestion.enable = false;
    enableCompletion = false;
    historySubstringSearch.enable = false;

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

    zimfw = {
      enable = true;
      degit = true;
      zimDir = "$HOME/.config/zsh/.zim";
      zimConfig = "$HOME/.config/zsh/.zimrc";
      zmodules = [
        # Core modules first
        "zimfw/environment"
        #"git"
        "zimfw/input"
        #"zimfw/termtitle"
        #"utility"
        "zimfw/magic-enter"

        # Info modules (need to be before prompt)
        #"zimfw/git-info"
        #"duration-info"
        #"prompt-pwd"

        "zimfw/exa"
        "zimfw/direnv"
        "zimfw/fzf"
        "zimfw/homebrew"

        "${toString ./zim/plugins} --source enhanced-paste.zsh"
        "${pkgs.zsh-fzf-tab}/share/fzf-tab --source fzf-tab.plugin.zsh"
        "${toString ./zim/plugins} --source thefuck.zsh"
        "${toString ./zim/plugins} --source zoxide.zsh"

        # Theme
        "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k --source powerlevel10k.zsh-theme"
        "${toString ./zim/plugins} --source p10k.zsh"

        # Completion modules
        "${pkgs.zsh-completions}/share/zsh/site-functions --fpath src"
        "${toString ./zim/plugins} --source completion.zsh"

        # Syntax highlighting
        "${toString ./zim/plugins} --source zsh-syntax-highlighting-dracula.zsh"
        "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting --source zsh-syntax-highlighting.zsh"
        "${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search --source zsh-history-substring-search.zsh"
        "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions --source zsh-autosuggestions.zsh"
      ];

      initAfterZim = ''
        # Additional history options not covered by Zim
        setopt HIST_FCNTL_LOCK
        setopt HIST_IGNORE_ALL_DUPS
        setopt HIST_EXPIRE_DUPS_FIRST
        setopt EXTENDED_HISTORY

        # First unbind all history-related keys
        bindkey -r '^[OA'
        bindkey -r '^[OB'
        bindkey -r '^[[A'
        bindkey -r '^[[B'

        # Bind both terminal modes to history-substring-search
        bindkey '^[OA' history-substring-search-up     # Up arrow (application mode)
        bindkey '^[OB' history-substring-search-down   # Down arrow (application mode)
        bindkey '^[[A' history-substring-search-up     # Up arrow (normal mode)
        bindkey '^[[B' history-substring-search-down   # Down arrow (normal mode)

        # Additional keybindings for different modes
        bindkey -M emacs '^P' history-substring-search-up
        bindkey -M emacs '^N' history-substring-search-down
        bindkey -M vicmd 'k' history-substring-search-up
        bindkey -M vicmd 'j' history-substring-search-down

        # History substring search configuration
        HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
        HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS='i'
        HISTORY_SUBSTRING_SEARCH_PREFIXED=1
      '';
    };
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = false; # will be handled by zim
    nix-direnv.enable = true;

    config = {
      load_dotenv = true;
      watch_file = [ ".env" ];
    };
  };
}   
