{ config, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    # Go itself
    go_1_23

    # Go tools
    gopls           # Language server
    golangci-lint   # Linter
    delve           # Debugger
    go-tools        # Additional tools like godoc, goimports, etc.
  ];

  # Go environment setup
  home.sessionVariables = {
    GOPATH = "$HOME/go";
    GOBIN = "$GOPATH/bin";
  };

  home.sessionPath = [
    "$GOBIN"
  ];

  programs.zsh = {
   shellAliases = {
      gob = "go build";
      gor = "go run";
      got = "go test ./... -v";
    };
  };

  # Create necessary Go directories
  home.activation = {
    createGoPaths = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG \
        ${config.home.homeDirectory}/go/{bin,pkg,src}
    '';
  };
} 