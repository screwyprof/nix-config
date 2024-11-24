{
  programs.direnv = {
    enable = true;
    enableZshIntegration = false; # will be handled by zim
    nix-direnv = {
      enable = true;
    };

    config = {
      load_dotenv = true;
      watch_file = [ ".env" ];
    };
  };
}
