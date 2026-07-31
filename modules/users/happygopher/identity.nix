{
  # Who the operator is, independent of where they work: a commit from inside a cage is still theirs.
  # `dev-git` carries git BEHAVIOUR and no identity, so identity sits next to the user, not the tool.
  flake.modules.homeManager.happygopher-identity = _: {
    programs.git.settings.user = {
      name = "Happy Gopher";
      email = "max@happygopher.nl";
    };
  };
}
