{
  flake.modules.homeManager.dev-direnv =
    { lib, ... }:
    {
      programs.direnv = {
        enable = true;
        enableZshIntegration = false; # will be handled by zim
        nix-direnv.enable = true;
        config = {
          load_dotenv = true;
          watch_file = [ ".env" ];
        };
      };

      # Load the directory's env BEFORE p10k's instant prompt (cli-zsh, mkBefore = 500): output here is allowed,
      # while the hook's `direnv: loading …` at the first prompt trips p10k's console-output warning. The hook
      # (zim) then finds the env loaded and stays quiet. p10k's documented recipe for direnv.
      programs.zsh.initContent = lib.mkOrder 400 ''
        (( ''${+commands[direnv]} )) && emulate zsh -c "$(direnv export zsh)"
      '';
    };
}
