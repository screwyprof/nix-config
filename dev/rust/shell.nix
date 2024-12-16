{ pkgs ? import <nixpkgs> {
    overlays = [ (import (builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz")) ];
  }
}:

let
  inherit (pkgs) lib;

  # Rust toolchain
  toolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;

  # Development tools
  devTools = with pkgs; [
    # Cargo extensions
    cargo-watch
    cargo-edit
    cargo-audit
    cargo-binutils
    #cargo-llvm-cov

    # Coverage tools
    lcov
    rustfilt
  ];

  # macOS specific dependencies
  darwinDeps = with pkgs; [
    darwin.apple_sdk.frameworks.CoreServices
    darwin.apple_sdk.frameworks.CoreFoundation
  ];

  # All Rust-related environment variables
  rustEnv = {
    RUST_BACKTRACE = "1";
    CARGO_NET_GIT_FETCH_WITH_CLI = "true";

    # Add cargo bin to PATH at the beginning
    PATH = "$HOME/.cargo/bin:${pkgs.lib.makeBinPath devTools}:$PATH";
  };
in
pkgs.mkShell {
  # Build inputs
  nativeBuildInputs = [ toolchain ] ++ devTools;
  buildInputs = lib.optionals pkgs.stdenv.isDarwin darwinDeps;

  # Environment
  inherit (rustEnv) RUST_BACKTRACE CARGO_NET_GIT_FETCH_WITH_CLI PATH;

  # Shell initialization 
  shellHook = ''
    echo "Rust development environment loaded"
    echo "Rust version: $(rustc --version)"
    echo "Cargo version: $(cargo --version)"

    # Check if cargo-llvm-cov is available in PATH after adding cargo bin
    if ! type cargo-llvm-cov >/dev/null 2>&1; then
      echo "Installing cargo-llvm-cov..."
      cargo install cargo-llvm-cov
    fi
  '';
}
