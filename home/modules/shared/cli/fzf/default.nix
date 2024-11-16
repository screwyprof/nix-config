{ lib, pkgs, ... }:
{
  programs = {
    fzf = {
      enable = true;
      enableZshIntegration = true;

      defaultOptions = [
        "--preview-window=right:60%:border-left"
        #"--color=bg:#011628,bg+:#143652,fg:#CBE0F0,header:#2CF9ED,hl:#B388FF,hl+:#B388FF,info:#06BCE4,marker:#2CF9ED,pointer:#2CF9ED,prompt:#2CF9ED,spinner:#2CF9ED"
      ];

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

      defaultCommand = "${pkgs.fd}/bin/fd --hidden --strip-cwd-prefix --exclude .git";

      fileWidgetCommand = "${pkgs.fd}/bin/fd --hidden --strip-cwd-prefix --exclude .git";
      fileWidgetOptions = [
        "--preview '([[ -d {} ]] && ${pkgs.eza}/bin/eza --tree --icons --git-ignore --level=2 --color=always {}) || ${pkgs.bat}/bin/bat --style=header,numbers,grid,changes --color=always {}'"
      ];

      changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type d --hidden --strip-cwd-prefix --exclude .git";
      changeDirWidgetOptions = [
        "--preview '${pkgs.eza}/bin/eza --tree --icons --git-ignore --level=2 --color=always {}'"
      ];
    };

    zsh = {
      plugins = [
        {
          name = "fzf-tab";
          src = pkgs.zsh-fzf-tab;
          file = "share/fzf-tab/fzf-tab.plugin.zsh";
        }
      ];

      initExtra = lib.mkAfter ''
        # Enable fzf-tab
        enable-fzf-tab

        source ${./fzf-comprun.sh}

        # Use same preview for fzf-tab as we do for fzf
        zstyle ':fzf-tab:complete:*:*' fzf-preview \
          '([[ -d $realpath ]] && ${pkgs.eza}/bin/eza --tree --icons --git-ignore --level=2 --color=always $realpath) || \
           ([[ -f $realpath ]] && ${pkgs.bat}/bin/bat --style=header,grid,numbers,changes --color=always $realpath) || echo $realpath'

        # Use fzf default options
        zstyle ':fzf-tab:*' use-fzf-default-opts yes
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
