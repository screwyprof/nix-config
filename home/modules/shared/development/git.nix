{ systemAdmin, ... }: {
  programs.git = {
    enable = true;
    userName = systemAdmin.fullName;
    userEmail = systemAdmin.email;

    delta = {
      enable = true;
      options = {
        features = "decorations";
        #side-by-side = true;
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
      url = {
        "https://github" = {
          insteadOf = "git://github";
        };
      };
    };

    aliases = {
      "fd" = "!f() { \
        target=\${1:-HEAD}; \
        preview=\"git diff --staged $target --color=always -- {-1} | delta\"; \
        git diff --staged $target --name-only | fzf -m --ansi --preview \"$preview\"; \
      }; f";

      fakecommit = "git commit --amend --no-edit && git push -f";
      cherrymaster = "git cherry -v master | cut -d ' ' -f3-";
      rmbranches = "git branch | grep -v 'master' | grep -v 'main' | xargs git branch -D";
    };

    ignores = [
      ".DS_Store"
      "*.swp"
      ".env"
      ".direnv"
      ".CFUserTextEncoding"
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
