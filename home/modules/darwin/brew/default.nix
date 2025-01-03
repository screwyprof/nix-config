{ inputs, lib, ... }:
{
  programs.zsh = {
    initExtra = ''
      if (( ! ''${fpath[(Ie)''${HOMEBREW_PREFIX}/share/zsh/site-functions]} )); then
        fpath=(''${HOMEBREW_PREFIX}/share/zsh/site-functions ''${fpath})
      fi
    '';
    zimfw = {
      zmodules = lib.mkMerge [
        (lib.mkOrder 400 [
          "${inputs.nix-homebrew.inputs.brew-src}/completions --fpath zsh"
          "${toString ./.} --fpath ."
        ])
      ];
    };
  };
}
