{ systemAdmin, ... }: {
  programs = {
    git = {
      enable = true;

      settings = {
        user = {
          inherit (systemAdmin) name email;
        };

        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        core = {
          editor = "vim";
          autocrlf = "input";
        };
        merge.conflictstyle = "diff3";
        diff.colorMoved = "default";
        url = {
          "https://github" = {
            insteadOf = "git://github";
          };
        };
      };

      ignores = [
        ".DS_Store"
        "*.swp"
        ".env"
        ".direnv"
        ".CFUserTextEncoding"
      ];
    };

    gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
        editor = "vim";
      };
    };

    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        features = "decorations";
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

    zsh.shellAliases = {
      git-fd = "git diff --staged HEAD --name-only | fzf -m --ansi --preview 'git diff --staged HEAD --color=always -- {} | delta'";
      git-fakecommit = "git commit --amend --no-edit && git push -f";
      git-cherry = "git cherry -v main | cut -d ' ' -f3-";
      git-rmbranches = "git branch | grep -v 'master' | grep -v 'main' | xargs git branch -D";
    };
  };
}
