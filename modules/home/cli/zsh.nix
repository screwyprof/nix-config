{
  flake.modules.homeManager.cli-zsh =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home = {
        sessionVariables = {
          NOSYSZSHRC = "1";

          YSU_MODE = "ALL"; # or "BESTMATCH"
          YSU_HARDCORE = "1";
          YSU_MESSAGE_POSITION = "after";

        };

        packages = with pkgs; [
          procs
          duf
          dust
          htop
          ripgrep
          shellcheck
          # ZIM modules - ensure they don't get GC'd
          zsh-fast-syntax-highlighting
          zsh-history-substring-search
          zsh-autosuggestions
          zsh-completions
          alias-teacher
          zsh-powerlevel10k
          zim-plugins
        ];
      };

      programs.zsh = {
        enable = true;
        dotDir = "${config.xdg.configHome}/zsh";
        #zprof.enable = true;

        # these are handled by zim
        autosuggestion.enable = false;
        enableCompletion = false;
        syntaxHighlighting.enable = false;

        defaultKeymap = "emacs";

        history = {
          size = 20000;
          save = 10000;
          path = "${config.xdg.stateHome}/zsh/.zsh_history";
          ignoreDups = true;
          ignoreAllDups = true;
          ignoreSpace = true;
          expireDuplicatesFirst = true;
          extended = true;
          share = true;
        };

        sessionVariables = {
          ZSH_CACHE_DIR = "$XDG_CACHE_HOME/zsh";
          ZSH_STATE_DIR = "$XDG_STATE_HOME/zsh";
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
              #"zimfw/magic-enter"
            ])

            # # Core functionality modules
            (lib.mkOrder 200 [
              "zimfw/direnv"
              #"zimfw/fzf"
              "zimfw/git"
              #"zimfw/homebrew"
            ])

            # Plugin modules
            (lib.mkOrder 300 [
              "${pkgs.alias-teacher}/share/zsh/plugins/alias-teacher --source alias-teacher.plugin.zsh"
            ])

            # # Theme (should be before completion and syntax highlighting)
            # # (lib.mkOrder 400 [
            # #   "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k --source powerlevel10k.zsh-theme"
            # #   "${pkgs.zim-plugins}/share/zsh/plugins/zim-plugins --source p10k.zsh"
            # # ])

            # Completion modules
            (lib.mkOrder 500 [
              "${pkgs.zsh-completions}/share/zsh/site-functions --fpath src"
              "${pkgs.zim-plugins}/share/zsh/plugins/zim-plugins --source completion.zsh"
            ])

            # Syntax highlighting (must be last)
            (lib.mkOrder 900 [
              #"${pkgs.zim-plugins}/share/zsh/plugins/zim-plugins --source zsh-syntax-highlighting-dracula.zsh"
              #"${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting --source zsh-syntax-highlighting.zsh"]
              "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting --source fast-syntax-highlighting.plugin.zsh"
              "${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search --source zsh-history-substring-search.zsh"
              "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions --source zsh-autosuggestions.zsh"
            ])
          ];

          # Keybindings provided by zimfw/input + emacs keymap (bindkey -e):
          #   History:    Up/Down/^P/^N  → history-substring-search (zimfw/input deferred precmd)
          #   Navigation: Home/End       → beginning/end-of-line    (zimfw/input via terminfo)
          #               ^A/^E          → beginning/end-of-line    (emacs keymap)
          #   Words:      Ctrl+Left/Right → backward/forward-word   (zimfw/input, 5 escape seqs)
          #               ^[b/^[f (Alt+b/f) → backward/forward-word (emacs keymap)
        };

        initContent = lib.mkBefore ''
          if [[ -r "''${XDG_CACHE_HOME:-''$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
            source "''${XDG_CACHE_HOME:-''$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
          fi

          # Disable zsh built-in log command to allow macOS log tool
          disable log

          # Disable paste highlight flash (breaks syntax highlighting)
          zle_highlight+=(paste:none)
        '';
      };
    };
}
