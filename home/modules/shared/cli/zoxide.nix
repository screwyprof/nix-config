{ config, lib, pkgs, ... }:
{
  home = {
    sessionVariables = {
      _ZO_DATA_DIR = "${config.xdg.stateHome}/zoxide";
    };

    packages = with pkgs; [
      fzf
      zoxide
      zim-plugins
    ];
  };

  programs = {
    zsh = {
      initContent = lib.mkAfter ''
              # Add z and zi wrapper functions for zoxide (in addition to enhanced cd)
              function z() {
                __zoxide_z "$@"
              }
        
              function zi() {
                __zoxide_zi "$@"
              }

              export _ZO_FZF_OPTS="$FZF_DEFAULT_OPTS --no-sort --cycle --wrap --tabstop=1 --exit-0 --bind=ctrl-z:ignore,btab:up,tab:down
        --preview='${pkgs.eza}/bin/eza --tree --all --icons --git-ignore --level=2 --color=always {2}'"
      '';

      zimfw.zmodules = lib.mkOrder 300 [
        "${pkgs.zim-plugins}/share/zsh/plugins/zim-plugins --source zoxide.zsh"
      ];
    };
  };
}
