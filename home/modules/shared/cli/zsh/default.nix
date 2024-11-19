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
    enableCompletion = true;
    autosuggestion = {
      enable = true;
      strategy = [ "history" "completion" ];
    };

    syntaxHighlighting = {
      enable = true;
      highlighters = [ "main" "brackets" "pattern" "cursor" "root" "line" ];
    };

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
    oh-my-zsh = {
      enable = true;
      theme = "powerlevel10k";
      custom = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k";
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
      ] ++ lib.optionals pkgs.stdenv.isDarwin [ "macos" ];
    };

    # Only load custom p10k config
    plugins = [
      {
        name = "powerlevel10k-config";
        src = ./p10k;
        file = "p10k.zsh";
      }
    ];

    # Initialize p10k instant prompt first
    initExtraFirst = ''
      zsh_cache="${config.xdg.cacheHome}/zsh"
      mkdir -p "$zsh_cache"

      # Ensure zcompdump uses XDG cache directory
      export ZSH_COMPDUMP="${config.xdg.cacheHome}/zsh/zcompdump-$ZSH_VERSION"
 
      # p10k instant prompt
      if [[ -r "${config.xdg.cacheHome}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "${config.xdg.cacheHome}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi
    '';

    initExtraBeforeCompInit = ''
      ZSH_DISABLE_COMPFIX=true
    '';

    profileExtra = ''
      # hook in brew
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
