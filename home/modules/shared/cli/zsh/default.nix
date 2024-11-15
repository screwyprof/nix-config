{ config, lib, pkgs, ... }: {
  home = {
    sessionVariables = {
      NOSYSZSHRC = "1"; # Prevent loading of /etc/zshrc
      TERM = "xterm-256color";

      # Prefer GNU versions over BSD ones
      PATH = lib.concatStringsSep ":" [
        "$HOME/.local/bin" # Local user binaries
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
      enableCompletion = false; # will be handled by oh-my-zsh
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      # And we can use the built-in history options
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

      initExtraFirst = ''
        # Disable oh-my-zsh's compfix
        ZSH_DISABLE_COMPFIX=true

        # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '';

      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          #"thefuck"
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
      ];

      initExtra = lib.mkBefore ''
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
        setopt HIST_VERIFY               # Show expanded history commands before executing.
      '';

      envExtra = ''
        # Force source the session variables in new shells
        if [ -e "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh" ]; then
          unset __HM_SESS_VARS_SOURCED
          . "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
        fi
      '';

      shellAliases = {
        # Modern CLI tool replacements
        ls = "${pkgs.eza}/bin/eza --icons=always";
        ll = "${pkgs.eza}/bin/eza -la --icons=always";
        tree = "${pkgs.eza}/bin/eza --tree --icons=always";
        du = "${pkgs.du-dust}/bin/dust";
        df = "${pkgs.duf}/bin/duf";
        top = "${pkgs.htop}/bin/htop";
        # GNU utils aliases
        grep = "${pkgs.gnugrep}/bin/grep --color=auto";
        sed = "${pkgs.gnused}/bin/sed";
        awk = "${pkgs.gawk}/bin/awk";
        tar = "${pkgs.gnutar}/bin/tar";
        make = "${pkgs.gnumake}/bin/make";
      };
    };
  };

  # Add required packages
  home.packages = with pkgs; [
    # Modern replacements for traditional tools
    procs # Modern process viewer (ps replacement)
    eza # Better ls
    duf # Better df
    du-dust # Better du
    htop # Better top
    ripgrep # Better grep
  ];
}
