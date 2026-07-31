{
  # WHO the operator is, independent of WHERE they are working. Shared by every devbox surface, because
  # a commit made from inside a cage is still the operator's commit — the cage's unix user is `dev`, but
  # the author is not.
  #
  # `dev-git` deliberately carries git BEHAVIOUR (rebase, autoSetupRemote, ignores) and no identity, so
  # identity lives here where it belongs, next to the user rather than next to the tool.
  flake.modules.homeManager.happygopher-identity = _: {
    programs.git.settings.user = {
      name = "Happy Gopher";
      email = "max@happygopher.nl";
    };
  };
}
