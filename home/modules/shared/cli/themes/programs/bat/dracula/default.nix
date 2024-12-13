{
  programs.bat = {
    config.theme = "base24-dracula";
    themes = {
      "base24-dracula" = {
        src = ./.;
        file = "base24_dracula.tmTheme";
      };
    };
  };
}
