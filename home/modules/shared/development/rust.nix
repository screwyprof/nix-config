{ pkgs, ... }:

let
  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    extensions = [
      "rust-src"
      # "rust-analyzer"
      # "clippy"
      # "rustfmt"
      #"lldb"
    ];
  };
in
{

  home.packages = [
    # Use rust-overlay's toolchain
    rustToolchain
  ];

  home.sessionVariables = {
    RUST_BACKTRACE = "1";
    CARGO_NET_GIT_FETCH_WITH_CLI = "true";
    # RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
    # RUSTC_PATH = "${rustToolchain}/bin/rustc";
    # CARGO_PATH = "${rustToolchain}/bin/cargo";
    # RUST_ANALYZER_PATH = "${rustToolchain}/bin/rust-analyzer";
  };
}
