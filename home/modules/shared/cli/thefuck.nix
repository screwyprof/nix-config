{ config, lib, pkgs, ... }: {
  programs.zsh = {
    initExtra = lib.mkBefore ''
      eval "$(thefuck --alias)"

      fuck-command-line() {
        # Get the failed command
        local cmd="$(fc -ln -1)"
        echo "Last command was: $cmd"  # Debug output
        
        # Run regular fuck command
        BUFFER="fuck"
        zle accept-line
      }

      zle -N fuck-command-line
      bindkey '\ef' fuck-command-line
    '';
  };

  home.packages = with pkgs; [
    thefuck
  ];

  home.sessionVariables = {
    THEFUCK_REQUIRE_CONFIRMATION = "true";
  };
}
