{ lib, ... }:
{
  # The VS Code extension CATALOG — bundles defined once, selected per surface:
  #   client → `programs.vscode` on the Mac   vmhost → this repo, via `mkServerLinks`
  #   cages  → each project's devbox session flake picks bundles
  #
  # Defining a bundle costs a surface nothing — only what it SELECTS is installed, so a Go cage has no
  # rust-analyzer: absent, not disabled.
  flake.lib.vscode = {

    bundles =
      pkgs:
      let
        e = pkgs.vscode-extensions;
        # Not in nixpkgs. A pin fixes exactly which bytes run and fails closed if the artifact changes.
        m = pkgs.vscode-utils.extensionFromVscodeMarketplace;
      in
      rec {
        # Every remote surface. Rule: would you want it in a language you have not used yet?
        base = [
          e.mkhl.direnv # loads the project devshell — why anything else is on PATH
          e.jnoortheen.nix-ide
          e.usernamehw.errorlens
          e.anthropic.claude-code # must run remote-side; declaring it stops anything re-installing it
        ];

        rust = [
          e.rust-lang.rust-analyzer
          e.tamasfe.even-better-toml
          e.vadimcn.vscode-lldb
          e.fill-labs.dependi
        ];

        go = [
          e.golang.go
          (m {
            publisher = "ryanluker";
            name = "vscode-coverage-gutters";
            version = "2.14.0";
            sha256 = "sha256-waF3FmncUsXqWFWGRy9X7RQ29BDRYlaqyFhEXg4HXNo=";
          })
          (m {
            publisher = "premparihar";
            name = "gotestexplorer";
            version = "0.1.13";
            sha256 = "sha256-CIqZ1yE9bAHuKvVcdD+Ph8kPgo/a9N+zqELYWxVV8F8=";
          })
        ];

        # Modelling/docs — testy-eventstorming only.
        model = [
          e.jebbs.plantuml
          e.contextmapper.context-mapper-vscode-extension
        ];

        # CLIENT-side only (`extensionKind: ui`) — `remote-ssh` IS the client half of remote.
        client = [
          e.dracula-theme.theme-dracula
          e.pkief.material-icon-theme
          e.pkief.material-product-icons
          e.ms-vscode-remote.remote-ssh
          e.ms-vscode-remote.remote-containers
        ];
      };

    # One symlink per extension into a remote server's extensions dir.
    #
    # Per-entry `home.file`, NOT a managed directory: the server writes its own `extensions.json` there,
    # so the dir must stay writable — an immutable whole-dir gives the `EntryWriteLocked` class this
    # config already hit on the Mac. home-manager still prunes entries it stops managing.
    mkServerLinks =
      exts:
      lib.listToAttrs (
        map (
          e:
          lib.nameValuePair ".vscode-server/extensions/${e.vscodeExtUniqueId}" {
            source = "${e}/share/vscode/extensions/${e.vscodeExtUniqueId}";
          }
        ) exts
      );
  };
}
