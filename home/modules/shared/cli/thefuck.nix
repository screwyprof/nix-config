{ config, lib, pkgs, ... }: {
  programs.zsh = {
    initExtra = lib.mkBefore ''
      # Initialize thefuck with standard mode
      eval "$(thefuck --alias)"

      # Custom function that executes fuck directly
      fuck-command-line() {
        BUFFER="fuck"
        zle accept-line
      }

      zle -N fuck-command-line
      bindkey '\ef' fuck-command-line
    '';
  };

  home.sessionVariables = {
    # Core settings
    THEFUCK_REQUIRE_CONFIRMATION = "true";
    THEFUCK_NO_COLORS = "false";
    THEFUCK_DEBUG = "false";

    # History settings
    THEFUCK_HISTORY_LIMIT = "2000";
    THEFUCK_ALTER_HISTORY = "true";

    # Rules configuration
    THEFUCK_PRIORITY = "no_command=9999:history=8000:sudo=1000";
    THEFUCK_RULES = "sudo:no_command:git_pull:git_push:npm_wrong_command";
    THEFUCK_EXCLUDE_RULES = "git_pull_uncommitted_changes";
  };

  home.packages = with pkgs; [
    thefuck
  ];
}
