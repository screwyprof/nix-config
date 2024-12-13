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
      ${config.iterm2Colors}
    '';
  };
}
