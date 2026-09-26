{
  flake.modules.homeManager.cli-eza =
    { lib, pkgs, ... }:
    let
      # Pinned, see cli-zsh.
      zimfwModule =
        repo: rev: hash:
        pkgs.fetchFromGitHub {
          owner = "zimfw";
          inherit repo rev hash;
        };
    in
    {
      home = {
        packages = [ pkgs.eza ];

        sessionVariables = {
          EZA_ICONS_AUTO = "1";
        };
      };

      programs.zsh = {
        shellAliases = {
          tree = "${pkgs.eza}/bin/eza --tree --all --icons --git-ignore --color=always";
        };

        zimfw.zmodules = lib.mkOrder 200 [
          "${zimfwModule "exa" "bb677b7f79a52774940fd9ca80431ee98635ef41"
            "sha256-HhLwor4Br/kfDfthfn1fBU/3ULQASUhuDAbqmX5SnAI="
          }"
        ];
      };
    };
}
