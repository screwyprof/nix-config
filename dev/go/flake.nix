{
  description = "Go development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];

      perSystem = { pkgs, ... }: {
        devShells.default = pkgs.mkShell {
          # Development tools
          buildInputs = with pkgs; [
            # Go tools
            go # Will be overridden by gopls based on go.mod
            gopls # Language server (handles Go version detection)
            delve # Debugger
            gotools # Standard Go tools
            golangci-lint # Linter
            checkmake # Makefile linter

            # Build tools
            gnumake
            gcc
          ];

          # Shell initialization
          shellHook = ''
            # Project root & stable hash (only set if not already defined for shell stacking)
            PROJECT_ROOT="''${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
            PROJECT_HASH="''${PROJECT_HASH:-$(printf '%s\n' "$PROJECT_ROOT" | shasum -a 256 | cut -c1-8)}"

            # Shared module cache + per-project binaries
            export GOPATH="''${XDG_DATA_HOME:-$HOME/.local/share}/go"
            export GOBIN="''${XDG_STATE_HOME:-$HOME/.local/state}/go-bin-$PROJECT_HASH"
            export PATH="$GOBIN:$PATH"

            # Create directories
            mkdir -p "$GOPATH/pkg/mod" "$GOBIN"

            echo "Go development environment loaded"
            echo "Go version: $(go version)"
            echo "GOPATH: $GOPATH"
            echo "GOBIN: $GOBIN"
            echo "Project root: $PROJECT_ROOT"
          '';
        };
      };
    };
}
