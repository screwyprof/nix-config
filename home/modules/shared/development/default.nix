{ config, lib, pkgs, ... }: {
  imports = [
    ./git.nix
    ./containers
    ./golang.nix
    ./node.nix
    ./vscode.nix
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home = {
    packages = with pkgs; [
      nix-prefetch-github
      nix-prefetch-git
      nixpkgs-fmt
      statix
      deadnix
    ];

    sessionVariables = {
      K9S_EDITOR = "vim";
      CARGO_NET_GIT_FETCH_WITH_CLI = "true";

      # libpq
      #LDFLAGS = "-L/opt/homebrew/opt/libpq/lib";
      #CPPFLAGS = "-I/opt/homebrew/opt/libpq/include";
      #PKG_CONFIG_PATH = "/opt/homebrew/opt/libpq/lib/pkgconfig";
      #PQ_LIB_DIR = "$(brew --prefix libpq)/lib";

      # libclang
      #LDFLAGS = "-L/opt/homebrew/opt/llvm/lib";
      #CPPFLAGS = "-I/opt/homebrew/opt/llvm/include";

      # Add these
      #AWS_PROFILE = "codefi";
    };
  };
}
