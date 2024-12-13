{ config, lib, ... }:

{
  options = {
    iterm2Colors = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "iTerm2 color sequences";
    };
  };

  config = {
    programs.zsh.initExtra = ''
      # Apply iTerm2 colors
      if [ -n "$ITERM_SESSION_ID" ]; then
        ${config.iterm2Colors}
      fi
    '';
  };
}
