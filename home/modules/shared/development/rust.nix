{ pkgs, ... }: {
  home.packages = with pkgs; [
    rustc
    cargo
    rustfmt
    rust-analyzer
    clippy
    lldb
  ];

  home.sessionVariables = {
    RUST_BACKTRACE = "1";
    CARGO_NET_GIT_FETCH_WITH_CLI = "true";
  };
}
