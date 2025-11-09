{
  description = "Rust development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];

      perSystem = { pkgs, system, ... }:
        let
          overlays = [ (import inputs.rust-overlay) ];
          pkgs = import inputs.nixpkgs { inherit system overlays; };

          # Rust toolchain - use stable as default, project can override
          toolchain = pkgs.rust-bin.stable.latest.default;

          # Development tools (battle-tested from favkit)
          devTools = with pkgs; [
            # Cargo extensions
            bacon
            cargo-edit
            cargo-audit
            cargo-binutils
            cargo-nextest
            cargo-watch

            # Coverage tools
            lcov

            # Linters
            checkmake
          ];

        in
        {
          devShells.default = pkgs.mkShell {
            # Build inputs
            nativeBuildInputs = [ toolchain ] ++ devTools;

            # Environment variables
            RUST_BACKTRACE = "full";
            CARGO_NET_GIT_FETCH_WITH_CLI = "true";
            CARGO_HTTP_MULTIPLEXING = "true";

            # Shell initialization
            shellHook = ''
              # Project root & stable hash (only set if not already defined for shell stacking)
              PROJECT_ROOT="''${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
              PROJECT_HASH="''${PROJECT_HASH:-$(printf '%s\n' "$PROJECT_ROOT" | shasum -a 256 | cut -c1-8)}"

              # Project-specific cargo directory (state/cache data)
              export CARGO_HOME="''${XDG_STATE_HOME:-$HOME/.local/state}/cargo-$PROJECT_HASH"
              export CARGO_TARGET_DIR="$CARGO_HOME/target"
              export PATH="$CARGO_HOME/bin:$PATH"

              # Create directories
              mkdir -p "$CARGO_HOME/bin"

              echo "Rust development environment loaded"
              echo "Rust version: $(rustc --version)"
              echo "Cargo version: $(cargo --version)"
              echo "CARGO_HOME: $CARGO_HOME"

              # Check if project has its own toolchain
              if [[ -f "rust-toolchain.toml" ]]; then
                echo "📋 Project toolchain detected:"
                if grep -q "channel" rust-toolchain.toml; then
                  CHANNEL=$(grep "channel" rust-toolchain.toml | cut -d= -f2 | tr -d ' "')
                  echo "   Channel: $CHANNEL"
                fi
                if grep -q "version" rust-toolchain.toml; then
                  VERSION=$(grep "version" rust-toolchain.toml | cut -d= -f2 | tr -d ' "')
                  echo "   Version: $VERSION"
                fi
                echo "   To use project toolchain: rustup toolchain install \$(grep -o 'channel.*' rust-toolchain.toml | cut -d= -f2 | tr -d ' \"')"
              fi

              # Install cargo-llvm-cov if not available (cached check)
              CARGO_LLVM_COV_MARKER="$CARGO_HOME/.cargo-llvm-cov-installed"
              if [[ ! -f "$CARGO_LLVM_COV_MARKER" ]]; then
                echo "Installing cargo-llvm-cov..."
                cargo install cargo-llvm-cov --quiet && touch "$CARGO_LLVM_COV_MARKER"
              fi

              # Show useful tools
              echo ""
              echo "Available tools:"
              echo "  • bacon          - cargo check runner"
              echo "  • cargo-nextest  - next-gen test runner"
              echo "  • cargo-llvm-cov - code coverage"
              echo "  • cargo-audit    - security audit"
            '';
          };
        };
    };
}
