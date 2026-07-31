{ lib, ... }:
{
  # The VS Code extension CATALOG — bundles defined once, selected per surface.
  #
  # Three consumers, one source of truth:
  #   client  → `programs.vscode` on the Mac (ui-kind only)
  #   vmhost  → the node's `~/.vscode-server/extensions` (this repo, via `mkServerLinks`)
  #   cages   → each project's devbox session flake picks bundles (devbox places them)
  #
  # Defining a bundle costs a surface nothing: only what a surface SELECTS is installed, so a Go project's
  # cage contains no rust-analyzer — absent, not disabled.
  flake.lib.vscode = {

    bundles =
      pkgs:
      let
        e = pkgs.vscode-extensions;
        # Not everything is in nixpkgs. A marketplace pin is publisher/name/version/sha256 —
        # content-addressed vetting: the hash fixes exactly which bytes run and fails closed if the
        # artifact ever changes. Stronger than an allowlist, which trusts the registry to keep serving
        # the same thing.
        m = pkgs.vscode-utils.extensionFromVscodeMarketplace;
      in
      rec {
        # Every remote surface, regardless of language. Membership rule: would you want this in a
        # project written in a language you have not used yet? If no, it belongs in a language bundle.
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

        # CLIENT-side only (`extensionKind: ui`): themes, icons and the Remote-* extensions run on the
        # Mac. Putting these in a remote set is a category error — `remote-ssh` IS the client half of
        # remote — so they are named here and consumed only by `programs.vscode`.
        client = [
          e.dracula-theme.theme-dracula
          e.pkief.material-icon-theme
          e.pkief.material-product-icons
          e.ms-vscode-remote.remote-ssh
          e.ms-vscode-remote.remote-containers
        ];
      };

    # Materialise a selection into a REMOTE server's extensions dir, as one symlink per extension.
    #
    # Per-entry `home.file`, NOT a managed directory: the VS Code server writes its own `extensions.json`
    # cache into that directory, so it must stay writable. An immutable whole-dir is what produces the
    # `EntryWriteLocked` / `name: 'Extract'` class this config already hit on the Mac. Home-manager still
    # prunes entries it stops managing, so the set converges without owning the directory itself.
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
