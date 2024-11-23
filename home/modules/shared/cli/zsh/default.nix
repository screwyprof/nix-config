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

    zimfw = {
      enable = true;
      degit = true;
      zimDir = "$HOME/.config/zsh/.zim";
      zimConfig = "$HOME/.config/zsh/.zimrc";
      zmodules = [
        # Core modules first
        #"environment"
        #"git"
        "input"
        #"termtitle"
        #"utility"
        "magic-enter"

        # Info modules (need to be before prompt)
        #"git-info"
        #"duration-info"
        #"prompt-pwd"

        "zimfw/exa"
        "zimfw/direnv"
        "zimfw/fzf"
        "zimfw/homebrew"

        "${pkgs.zsh-fzf-tab}/share/fzf-tab --source fzf-tab.plugin.zsh"
        "${toString ./zim/plugins} --source thefuck.zsh"
        "${toString ./zim/plugins} --source zoxide.zsh"

        # Theme
        "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k --source powerlevel10k.zsh-theme"
        "${toString ./zim/plugins} --source p10k.zsh"

        # Completion modules
        "${toString pkgs.zsh-completions}/share/zsh/site-functions --fpath src"
        "${toString ./zim/plugins} --source completion.zsh"

        # Syntax highlighting
        "${toString ./zim/plugins} --source zsh-syntax-highlighting-dracula.zsh"
        "${toString pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting --source zsh-syntax-highlighting.zsh"
        "${toString pkgs.zsh-autosuggestions}/share/zsh-autosuggestions --source zsh-autosuggestions.zsh"
      ];
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
