{ lib, ... }:
{
  # The VS Code extension CATALOG — bundles defined once, selected per surface:
  #   client → `programs.vscode` on the Mac   vmhost → this repo, via `mkServerExtensions`
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

    # A remote server's extensions dir, in either of the two shapes home-manager itself offers for the
    # CLIENT via `mutableExtensionsDir`. Returns `home.file` entries either way, so the call site is the
    # same and switching is one argument.
    #
    # DEFAULT IMMUTABLE, matching `vscode.nix`'s `mutableExtensionsDir = false` on the client: one symlink
    # to a `buildEnv` that also carries a nix-generated `extensions.json`. The declared set is the whole
    # truth, replaced wholesale on every change.
    #
    # WHY IMMUTABLE WON (all three legs of the mutable case failed, 2026-08-08):
    #   1. "home-manager cannot place a SERVER extensions dir" — it can; this function is the proof, and
    #      it already runs on the login home.
    #   2. "mutable fails soft on a reflex `--install-extension`" — it does not FAIL, it SUCCEEDS and is
    #      reverted by the next placement. Worse under per-entry `home.file`, where home-manager prunes
    #      only what it managed: an ad-hoc install is never tracked, so it survives every rebuild as
    #      undeclared drift.
    #   3. "do not replace working code" — the code being replaced is devbox's, and it is being deleted
    #      (screwyprof/devbox#481).
    #
    # MEASURED against the real server (v1.129.1, `code-server` from a placed Stable-<commit>):
    #   - nix-generated manifest accepted: `--list-extensions --show-versions` exit 0, all 7 with versions
    #   - everyday listing from a 0555 dir: exit 0
    #   - REMOVAL by construction: rebuilt env 7 -> 4 lists exactly 4, no stale entries, no invalid warnings
    #   - `--install-extension` into it: `EACCES` then an unhandled `name: 'Extract'` exception, exit 1.
    #     That is the accepted cost, and it is the same cost the client already pays.
    #
    # The MUTABLE branch is kept because the trade is worth re-taking if VS Code ever refuses an ad-hoc
    # install gracefully instead of crashing. It needs a sentinel: the server writes `extensions.json`
    # itself and does NOT reconcile it, so a removed extension stays listed as `isValid: false` and warns
    # on every connect. `home.file`'s `onChange` is the change detector — no hash of our own — and it is
    # keyed on STORE PATHS because the cache records `version`, so a bump makes it stale too.
    #
    # SWITCHING mutable -> immutable needs a one-time `rm -rf ~/.vscode-server/extensions` per home: the
    # directory holds files home-manager never managed (the server's `extensions.json`, any ad-hoc
    # install), and it refuses to clobber those. The reverse direction needs nothing.
    mkServerExtensions =
      {
        pkgs,
        exts,
        mutable ? false,
      }:
      if mutable then
        lib.listToAttrs (
          map (
            e:
            lib.nameValuePair ".vscode-server/extensions/${e.vscodeExtUniqueId}" {
              source = "${e}/share/vscode/extensions/${e.vscodeExtUniqueId}";
            }
          ) exts
        )
        // {
          ".vscode-server/extensions/.hm-declared-extensions.json" = {
            text = builtins.toJSON (map (e: "${e}") exts);
            onChange = ''
              run rm -f "$HOME/.vscode-server/extensions/extensions.json"
            '';
          };
        }
      else
        {
          ".vscode-server/extensions".source =
            let
              # The server reads this INDEX instead of scanning; without it an immutable dir is broken
              # outright, not merely install-hostile ("Unable to read file ... extensions.json").
              manifest = pkgs.writeTextFile {
                name = "vscode-server-extensions-json";
                text = pkgs.vscode-utils.toExtensionJson exts;
                destination = "/share/vscode/extensions/extensions.json";
              };
            in
            "${
              pkgs.buildEnv {
                name = "vscode-server-extensions";
                paths = exts ++ [ manifest ];
              }
            }/share/vscode/extensions";
        };
  };
}
