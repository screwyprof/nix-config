{ config, lib, pkgs, ... }: {
  programs.go = {
    enable = true;
    package = pkgs.go_1_23;
    goPath = "go"; # This creates ~/go
    goBin = "go/bin"; # This creates ~/go/bin
  };

  # Additional Go tools can be installed via home.packages
  home.packages = with pkgs; [
    gopls
    delve
    go-tools
    golangci-lint
  ];

  programs.zsh.shellAliases = {
    gob = "go build";
    gor = "go run";
    got = "go test ./... -v";
  };
}
