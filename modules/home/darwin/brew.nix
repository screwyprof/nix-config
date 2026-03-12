{ inputs, ... }:
let
  masCompletions = builtins.path {
    name = "mas-completions";
    path = ./mas-completions;
  };
in
{
  flake.modules.homeManager.darwin-brew =
    { lib, ... }:
    {
      programs.zsh = {
        initContent = lib.mkOrder 100 ''
          eval "$(/opt/homebrew/bin/brew shellenv)"
          if (( ! ''${fpath[(Ie)''${HOMEBREW_PREFIX}/share/zsh/site-functions]} )); then
            fpath=(''${HOMEBREW_PREFIX}/share/zsh/site-functions ''${fpath})
          fi
        '';
        zimfw = {
          zmodules = lib.mkMerge [
            (lib.mkOrder 400 [
              "${inputs.nix-homebrew.inputs.brew-src}/completions --fpath zsh"
              "${masCompletions} --fpath ."
            ])
          ];
        };
      };
    };
}
