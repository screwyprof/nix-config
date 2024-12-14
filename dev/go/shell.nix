# Development shell for Go
{ pkgs ? import <nixpkgs> { } }:

let
  # Development tools
  devTools = with pkgs; [
    # Go tools
    go # Will be overridden by gopls based on go.mod
    gopls # Language server (handles Go version detection)
    delve # Debugger
    go-tools # Additional tools like godoc
    golangci-lint # Linter
    gotools # Standard Go tools

    # Build tools
    gnumake
    gcc
  ];
in
pkgs.mkShell {
  # Build inputs
  buildInputs = devTools;

  # Shell initialization
  shellHook = ''
    # Set up GOPATH in the project directory
    export GOPATH="$PWD/.go"
    export PATH="$GOPATH/bin:$PATH"

    echo "Go development environment loaded"
    echo "Go version: $(go version)"
    echo "GOPATH: $GOPATH"
  '';
}
