{ inputs, lib, ... }:
# let
#   brewPrefix =
#     if pkgs.stdenv.isDarwin && pkgs.stdenv.isAarch64
#     then "/opt/homebrew"
#     else "/usr/local";
# in
{
  programs.zsh = {
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
