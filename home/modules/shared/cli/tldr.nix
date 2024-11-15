{
  programs.tealdeer = {
    enable = true;
    settings = {
      updates = {
        auto_update = true;
      };
      display = {
        use_pager = false;
        compact = false;
      };
      style = {
        description = { foreground = "yellow"; };
        command_name = { foreground = "cyan"; };
        example_text = { foreground = "green"; };
        example_code = { foreground = "blue"; };
        example_variable = { foreground = "red"; };
      };
    };
  };
}
