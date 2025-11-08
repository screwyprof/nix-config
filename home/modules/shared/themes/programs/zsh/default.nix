{ lib, pkgs, ... }:

let
  p10kConfig = pkgs.writeTextFile {
    name = "my-p10k-config";
    text = builtins.readFile ./p10k.zsh;
    destination = "/p10k.zsh";
  };

in
{
  programs.zsh = {
    zimfw = {
      zmodules = lib.mkOrder 400 [
        "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k --source powerlevel10k.zsh-theme"
        "${p10kConfig} --source p10k.zsh"
      ];
    };
  };

  # Add p10kConfig to packages to create GC dependency
  home.packages = [ p10kConfig ];
}
