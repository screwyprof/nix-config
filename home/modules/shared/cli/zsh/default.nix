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

    # these are handled by zim
    autosuggestion.enable = false;
    enableCompletion = false;
    syntaxHighlighting.enable = false;

    defaultKeymap = "emacs";

    history = {
      size = 20000;
      save = 10000;
      path = "$ZDOTDIR/.zsh_history";
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
      extended = true;
      share = true;
    };

    shellAliases = modernCLI // gnuUtils;

    sessionVariables = {
      YSU_MODE = "ALL"; # or "BESTMATCH"
      YSU_HARDCORE = "1";
      YSU_MESSAGE_POSITION = "after";
    };

    zimfw = {
      enable = true;
      degit = true;
      zimDir = "$HOME/.config/zsh/.zim";
      zimConfig = "$HOME/.config/zsh/.zimrc";
      zmodules = lib.mkMerge [
        # Early modules (environment, input, etc.)
        (lib.mkOrder 100 [
          "zimfw/environment"
          "zimfw/input"
          #"zimfw/termtitle"
          "zimfw/utility"
          "zimfw/magic-enter"
        ])

        # Core functionality modules
        (lib.mkOrder 200 [
          "zimfw/exa"
          "zimfw/direnv"
          "zimfw/fzf"
          "zimfw/git"
          "zimfw/homebrew"
        ])

        # Plugin modules
        (lib.mkOrder 300 [
          "${toString ./zim/plugins} --source enhanced-paste.zsh"
          "${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use --source you-should-use.plugin.zsh"
        ])

        # Theme (should be before completion and syntax highlighting)
        # (lib.mkOrder 400 [
        #   "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k --source powerlevel10k.zsh-theme"
        #   "${toString ./zim/plugins} --source p10k.zsh"
        # ])

        # Completion modules
        (lib.mkOrder 500 [
          "${pkgs.zsh-completions}/share/zsh/site-functions --fpath src"
          "${toString ./zim/plugins} --source completion.zsh"
        ])

        # Syntax highlighting (must be last)
        (lib.mkOrder 900 [
          "${toString ./zim/plugins} --source zsh-syntax-highlighting-dracula.zsh"
          "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting --source zsh-syntax-highlighting.zsh"
          "${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search --source zsh-history-substring-search.zsh"
          "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions --source zsh-autosuggestions.zsh"
        ])
      ];

      historySearch = {
        enable = true;
        searchUpKey = [
          "^[OA" # Up arrow (application mode)
          "^[[A" # Up arrow (normal mode)
          "^P" # Ctrl+P (emacs mode)
        ];
        searchDownKey = [
          "^[OB" # Down arrow (application mode)
          "^[[B" # Down arrow (normal mode)
          "^N" # Ctrl+N (emacs mode)
        ];
      };

      initAfterZim = ''
        # Ctrl+A and Ctrl+E for beginning and end of line
        bindkey '^A' beginning-of-line  # Ctrl+A
        bindkey '^E' end-of-line        # Ctrl+E

        # Word movement with Option+Left/Right (Emacs-style)
        bindkey '^[f' forward-word      # Option+Right
        bindkey '^[b' backward-word     # Option+Left
      '';
    };
  };
}   
