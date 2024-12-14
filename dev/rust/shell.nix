# Development shell for Rust
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
    cargo-outdated
    cargo-binutils

    # Build tools
    # pkg-config
    # openssl
    # libiconv

    # Coverage tools
    lcov
    rustfilt
  ];

  # macOS specific dependencies
  darwinDeps = with pkgs; [
    darwin.apple_sdk.frameworks.CoreServices
    darwin.apple_sdk.frameworks.CoreFoundation
  ];

  # Environment variables for code coverage
  coverageEnv = {
    CARGO_INCREMENTAL = "0";
    RUSTFLAGS = "-Cinstrument-coverage --cfg coverage_nightly";
    LLVM_PROFILE_FILE = "target/coverage/coverage-%p-%m.profraw";
  };
in
pkgs.mkShell {
  # Build inputs
  nativeBuildInputs = [ toolchain ] ++ devTools;
  buildInputs = lib.optionals pkgs.stdenv.isDarwin darwinDeps;

  # Environment
  inherit (coverageEnv) CARGO_INCREMENTAL RUSTFLAGS LLVM_PROFILE_FILE;

  # Shell initialization
  shellHook = ''
    # Add cargo bin directory to PATH
    export PATH="$HOME/.cargo/bin:$PATH"
    
    # Basic environment setup
    export RUST_BACKTRACE="1"
    export CARGO_NET_GIT_FETCH_WITH_CLI="true"
    
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
