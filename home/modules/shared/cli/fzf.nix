{ config, lib, pkgs, ... }: {
  programs = {
    fzf = {
      enable = true;
      enableZshIntegration = true;

      colors = {
        fg = "#CBE0F0";
        bg = "#011628";
        "bg+" = "#143652";
        hl = "#B388FF";
        "hl+" = "#B388FF";
        info = "#06BCE4";
        prompt = "#2CF9ED";
        pointer = "#2CF9ED";
        marker = "#2CF9ED";
        spinner = "#2CF9ED";
        header = "#2CF9ED";
      };

      defaultCommand = "${pkgs.fd}/bin/fd --type f --hidden --exclude .git";
      fileWidgetCommand = "${pkgs.fd}/bin/fd --type f --hidden --exclude .git";
      fileWidgetOptions = [
        "--preview '([[ -f {} ]] && ${pkgs.bat}/bin/bat --style=numbers --color=always --line-range :500 {}) || ([[ -d {} ]] && ${pkgs.eza}/bin/eza --tree --color=always {} | head -200) || echo {}'"
        "--preview-window=right:60%"
      ];
      changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type d --hidden --exclude .git";
      changeDirWidgetOptions = [
        "--preview '${pkgs.eza}/bin/eza --tree --color=always {} | head -200'"
        "--preview-window=right:60%"
      ];

      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
        "--inline-info"
      ];
    };

    zsh = {
      plugins = [
        {
          name = "fzf-tab";
          src = pkgs.fetchFromGitHub {
            owner = "Aloxaf";
            repo = "fzf-tab";
            rev = "master";
            sha256 = "sha256-EWMeslDgs/DWVaDdI9oAS46hfZtp4LHTRY8TclKTNK8=";
          };
        }
      ];

      initExtra = ''
        # fzf-tab configuration
        enable-fzf-tab
        zstyle ':fzf-tab:*' fzf-command fzf
        zstyle ':fzf-tab:*' fzf-flags '--height 40% --preview-window=right:60%'
        zstyle ':fzf-tab:complete:cd:*' fzf-preview '${pkgs.eza}/bin/eza --tree --color=always $realpath'
        zstyle ':fzf-tab:complete:*' fzf-preview '([[ -f $realpath ]] && ${pkgs.bat}/bin/bat --style=numbers --color=always --line-range :500 $realpath) || ([[ -d $realpath ]] && ${pkgs.eza}/bin/eza --tree --color=always $realpath | head -200) || echo $realpath'
      '';
    };
  };

  home.packages = with pkgs; [
    fd
    bat
    eza
    dnsutils
  ];
}
