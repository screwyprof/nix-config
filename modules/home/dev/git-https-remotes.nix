{
  # NOT in `dev-git`: that aspect also reaches the Mac, which has a working SSH key. These homes have
  # none and authenticate with the gh credential helper instead.
  flake.modules.homeManager.dev-git-https-remotes = _: {
    programs.git.settings.url."https://github.com/".insteadOf = [
      "git@github.com:"
      "ssh://git@github.com/"
    ];
  };
}
