{ pkgs, devUser, ... }: {
  programs.git = {
    enable = true;
    userName = devUser.fullName;
    userEmail = devUser.email;

    delta = {
      enable = true;
      options = {
        features = "decorations";
        side-by-side = true;
        line-numbers = true;
        line-numbers-left-format = "{nm:>4}│";
        line-numbers-right-format = "{np:>4}│";
        syntax-theme = "Dracula";
        minus-style = "syntax '#3f2d3d'";
        plus-style = "syntax '#2d3f2d'";
        file-style = "bold yellow ul";
        file-decoration-style = "none";
        hunk-header-decoration-style = "cyan box";
        hunk-header-file-style = "red";
        hunk-header-line-number-style = "#067a00";
        hunk-header-style = "file line-number syntax";
        navigate = true;
        tabs = 4;
        true-color = "always";
        zero-style = "syntax";
      };
    };

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core = {
        editor = "vim";
        autocrlf = "input";
      };
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
    };

    aliases = {
      st = "status";
      ci = "commit";
      co = "checkout";
      br = "branch";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      visual = "!gitk";
    };

    ignores = [
      ".DS_Store"
      "*.swp"
      ".env"
      ".direnv"
    ];
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "vim";
    };
  };
}
