{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" ];
        };
      in
      {
        devShells.default = with pkgs; mkShell {
          buildInputs = [
            openssl
            pkg-config
            eza
            fd
            rustToolchain
          ];

          shellHook = ''
                          # Create a directory for our toolchain
                          mkdir -p .direnv/bin

                          # Symlink all Rust tools to make them discoverable as a toolchain
                          ln -sf ${rustToolchain}/bin/rustc .direnv/bin/rustc
                          ln -sf ${rustToolchain}/bin/cargo .direnv/bin/cargo
                          ln -sf ${rustToolchain}/bin/rust-analyzer .direnv/bin/rust-analyzer
                          ln -sf ${rustToolchain}/bin/rustfmt .direnv/bin/rustfmt

                          # Add our toolchain directory to PATH (should be first)
                          export PATH="$PWD/.direnv/bin:$PATH"

            #            # Create .env with Rust paths
            #            cat > .env << EOF
            #            RUST_SRC_PATH="${rustToolchain}/lib/rustlib/src/rust/library"
            #            RUSTC_PATH="${rustToolchain}/bin/rustc"
            #            CARGO_PATH="${rustToolchain}/bin/cargo"
            #            RUST_ANALYZER_PATH="${rustToolchain}/bin/rust-analyzer"
            #            EOF
            #
            #            # Create .envrc to load .env
            #            cat > .envrc << EOF
            #            use flake .
            #            dotenv_if_exists
            #            EOF
            #            direnv allow
          '';
        };
      }
    );
}
