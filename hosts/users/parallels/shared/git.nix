{ pkgs, devUser, ... }: {
  programs.git = {
    enable = true;
    userName = devUser.fullName;
    userEmail = devUser.email;

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

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "vim";
    };
  };
}
