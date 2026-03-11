{
  flake.modules.homeManager.cli-fzf =
    { lib, pkgs, ... }:
    let
      fdCmd = "${pkgs.fd}/bin/fd --strip-cwd-prefix --hidden --follow --exclude .git --exclude node_modules --exclude .cache --exclude Library";
    in
    {
      programs = {
        fzf = {
          enable = true;
          # Disabled: fzf keybindings are sourced via zimfw zmodule
          enableZshIntegration = false;

          defaultOptions = [
            "--multi"
            "--height=50%"
            "--no-separator"
            "--border"
            "--layout=reverse"
            "--padding=1"
            "--preview-window=right:60%:border-none"
            "--bind=ctrl-/:toggle-preview"
            "--ansi"
            "--algo=v2"
          ];

          defaultCommand = "${fdCmd}";

          fileWidgetCommand = "${fdCmd} --type f";
          fileWidgetOptions = [
            "--preview '([[ -d {} ]] && ${pkgs.eza}/bin/eza --tree --all --icons --git-ignore --level=3 --color=always {} || ${pkgs.bat}/bin/bat --style=header,numbers,changes --color=always {})'"
          ];

          changeDirWidgetCommand = "${fdCmd} --type d";
          changeDirWidgetOptions = [
            "--preview '${pkgs.eza}/bin/eza --tree --all --icons --git-ignore --level=3 --color=always {}'"
            "--bind 'change:reload:${fdCmd} --type d'"
          ];
        };

        zsh = {
          initContent = lib.mkAfter ''
            ## Use fzf default options
            zstyle ':fzf-tab:*' use-fzf-default-opts yes
            zstyle ':fzf-tab:*' fzf-min-height 8
            zstyle ':fzf-tab:*' popup-min-size 80 8
            zstyle ':fzf-tab:*' switch-group '<' '>'

            ## force zsh not to show completion menu
            zstyle ':completion:*' menu no

            ## Command completion (cd<tab>, ssh<tab>, etc)
            zstyle ':fzf-tab:complete:*:commands' fzf-preview 'which {}'

            ## ssh<space><tab>
            zstyle ':fzf-tab:complete:ssh:*' fzf-preview '
              echo "=== Host: $word ==="
              if [ -f ~/.ssh/config ] && grep -q "^Host $word" ~/.ssh/config; then
                echo "\n=== SSH Config (~/.ssh/config) ==="
                line=$(grep -n "^Host $word" ~/.ssh/config | cut -d: -f1)
                echo "# Host $word found: line $line"
                grep -A 4 "^Host $word" ~/.ssh/config
              elif ${pkgs.openssh}/bin/ssh-keygen -F $word > /dev/null 2>&1; then
                echo "\n=== Known Host (~/.ssh/known_hosts) ==="
                ${pkgs.openssh}/bin/ssh-keygen -F $word
              elif grep -q "$word" /etc/hosts; then
                echo "\n=== System Host (/etc/hosts) ==="
                line=$(grep -n "$word" /etc/hosts | cut -d: -f1)
                echo "# Host $word found: line $line"
                grep "$word" /etc/hosts
              fi'

            ## export|unset<space><tab>
            zstyle ':fzf-tab:complete:(export|unset):*' fzf-preview '
              echo "=== $word ==="
              eval "echo \$$word"
              description=$(case $word in
                PATH)        echo "List of directories to search for commands";;
                HOME)        echo "User home directory";;
                SHELL)       echo "Default shell";;
                EDITOR)      echo "Default text editor";;
                LANG)        echo "Default system language";;
                TERM)        echo "Terminal type";;
                SSH_*)       echo "SSH session variable";;
                DISPLAY)     echo "X11 display address";;
                XDG_*)       echo "XDG specification directory";;
                LC_*)        echo "Locale setting";;
                *)           echo "";;
              esac)
              if [ -n "$description" ]; then
                echo "\nDescription: $description"
              fi
              if env | grep -q "^$word="; then
                echo "\nType: Environment variable (available to child processes)"
              else
                echo "\nType: Shell variable (only available in current shell)"
              fi'

            ## cd<space><tab> - directory completion
            zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --all --icons --git-ignore --level=3 --color=always $word'

            ## file/directory preview for other completions
            zstyle ':fzf-tab:complete:*:(files|directories):*' fzf-preview '([[ -d $word ]] && eza --tree --all --icons --git-ignore --level=3 --color=always $word || bat --style=header,numbers,changes --color=always $word)'
          '';

          zimfw.zmodules = lib.mkOrder 300 [
            {
              cachedInit = [
                "${pkgs.fzf}/bin/fzf"
                "--zsh"
              ];
            }
            {
              path = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
              source = "fzf-tab.plugin.zsh";
            }
            {
              path = "${pkgs.zsh-forgit}/share/zsh/zsh-forgit";
              source = "forgit.plugin.zsh";
            }
          ];
        };
      };

      home.packages = with pkgs; [
        fd
        bat
        eza
        git
        zsh-fzf-tab
        zsh-forgit
      ];
    };
}
