{ pkgs, ... }: {
  programs.git = {
    enable = true;
    userName = "Your Name";  # TODO: Replace with your name
    userEmail = "your.email@example.com";  # TODO: Replace with your email
    
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core = {
        editor = "vim";
        autocrlf = "input";
      };
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
      "result"
    ];
  };

  # GitHub CLI configuration
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "vim";
    };
  };
} 