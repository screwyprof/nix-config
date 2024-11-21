{ lib, pkgs, ... }:
{
  programs = {
    fzf = {
      enable = true;
      enableZshIntegration = true;

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
      ];

      # dracula
      # colors = {
      #   fg = "#f8f8f2"; # Foreground
      #   bg = "#282a36"; # Background
      #   "bg+" = "#44475a"; # Selected background
      #   hl = "#bd93f9"; # Highlight
      #   "hl+" = "#bd93f9"; # Selected highlight
      #   info = "#ffb86c"; # Info
      #   prompt = "#50fa7b"; # Prompt
      #   pointer = "#ff79c6"; # Pointer
      #   marker = "#ff79c6"; # Marker
      #   spinner = "#ffb86c"; # Spinner
      #   header = "#6272a4"; # Header
      #   border = "#bd93f9"; # Border (matching highlight color)
      # };

      defaultCommand = "${pkgs.fd}/bin/fd --strip-cwd-prefix --hidden --follow --exclude .git";

      fileWidgetCommand = "${pkgs.fd}/bin/fd --strip-cwd-prefix --hidden --follow --exclude .git";
      fileWidgetOptions = [
        "--preview '([[ -d {} ]] && ${pkgs.eza}/bin/eza --tree --all --icons --git-ignore --level=3 --color=always {} || ${pkgs.bat}/bin/bat --style=header,numbers,changes --color=always {})'"
      ];

      changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type d --strip-cwd-prefix --hidden --follow --exclude .git --exclude node_modules";
      changeDirWidgetOptions = [
        "--preview '${pkgs.eza}/bin/eza --tree --all --icons --git-ignore --level=3 --color=always {}'"
      ];
    };

    zsh = {
      # plugins = [
      #   {
      #     name = "fzf-tab";
      #     src = pkgs.zsh-fzf-tab;
      #     file = "share/fzf-tab/fzf-tab.plugin.zsh";
      #   }
      #   {
      #     name = "forgit";
      #     src = pkgs.zsh-forgit;
      #     file = "share/zsh/zsh-forgit/forgit.plugin.zsh";
      #   }
      #   {
      #     name = "fzf-git.zsh";
      #     src = pkgs.fetchFromGitHub {
      #       owner = "junegunn";
      #       repo = "fzf-git.sh";
      #       rev = "f730cfa1860acdb64597a0cf060d4949f1cd02a8";
      #       sha256 = "sha256-7IUCIaP2suAtrvSKvIJ/Oledm+3heZCBcTy56XgtIYo=";
      #     };
      #     file = "fzf-git.sh";
      #   }
      # ];

      initExtra = lib.mkAfter ''
        # Enable fzf-tab
        enable-fzf-tab

        # Use fzf default options
        zstyle ':fzf-tab:*' use-fzf-default-opts yes

        # force zsh not to show completion menu
        zstyle ':completion:*' menu no

        # Command completion (cd<tab>, ssh<tab>, etc)
        zstyle ':fzf-tab:complete:*:commands' fzf-preview 'which {}'

        ## ssh<space><tab>
        ### First, set up SSH completion to only use our specified hosts
        zstyle ':completion:*:*:ssh:*' tag-order 'hosts:-host:host'
        zstyle ':completion:*:*:ssh:*' group-order hosts-host
        zstyle ':completion:*:ssh:*' completer _ssh _complete _hosts

        ### Then add hosts from various sources
        zstyle ':completion:*:hosts' hosts $(
          (
            cat ~/.ssh/config 2>/dev/null | sed -n 's/^Host \([^ *]*\)/\1/p';
            cat ~/.ssh/known_hosts 2>/dev/null | cut -d ' ' -f1 | tr ',' '\n' | sed 's/\[//g;s/\]//g';
            cat /etc/hosts 2>/dev/null | grep -v '^#' | awk '{print $2}'
          ) | sort -u
        )
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
        
        # export|unset<space><tab>
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

        # cd<space><tab> - directory completion
        zstyle ':fzf-tab:complete:cd:*' fzf-preview '${pkgs.eza}/bin/eza --tree --all --icons --git-ignore --level=3 --color=always $word'

        # File/directory preview for other completions
        zstyle ':fzf-tab:complete:*:(files|directories):*' fzf-preview '([[ -d $word ]] && ${pkgs.eza}/bin/eza --tree --all --icons --git-ignore --level=3 --color=always $word || ${pkgs.bat}/bin/bat --style=header,numbers,changes --color=always $word)'
      '';
    };
  };

  home.packages = with pkgs; [
    fd
    bat
    eza
    git
  ];

  # Create the fzf config directory
  xdg.configFile."fzf/.keep".text = "";
}
