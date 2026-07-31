{ lib, ... }:
{
  # The VS Code REMOTE server + CLI, fetched from Microsoft and pinned.
  #
  # Remote-SSH downloads ~635MB of server into every remote `$HOME` it connects to, and the install gates
  # are pure existence checks — `[ -f "$CLI_PATH" ]` for the CLI, `target_dir.exists()` for the server. So
  # placing these from the store suppresses both downloads entirely: one copy per commit, shared by every
  # home, instead of one copy per home.
  #
  # THE COMMIT IS DERIVED, NOT DECLARED. `pkgs.vscode.rev` is the same commit Remote-SSH negotiates with,
  # so bumping nixpkgs moves this in lockstep with the editor. Only the content hashes are hand-carried,
  # keyed by rev — so a bump that outruns them WARNS and degrades to letting VS Code download, rather than
  # silently pinning the wrong bytes.
  #
  # This holds only while the MAC and the NODE resolve the same nixpkgs. The effective commit is the
  # client's; this pin follows the node's. `programs.vscode` on the Mac disables both update checks and
  # `update.mode`, so the client cannot drift on its own — but rebuilding one machine and not the other
  # can skew them, and nothing here detects that: `staleWarning` fires on "no pin for the NODE's rev",
  # never on "node rev ≠ client rev". The symptom is a silent return to downloading.
  #
  # Refresh a hash WITHOUT downloading — the update service returns the digest in a HEAD header:
  #   curl -fsSI https://update.code.visualstudio.com/commit:<rev>/<platform>/stable | grep -i x-sha256
  #   nix hash convert --hash-algo sha256 --to sri <hex>
  flake.lib.vscodeRemote =
    pkgs:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      rev = pkgs.vscode.rev;

      platforms = {
        aarch64-linux = {
          server = "server-linux-arm64";
          cli = "cli-alpine-arm64";
        };
        x86_64-linux = {
          server = "server-linux-x64";
          cli = "cli-alpine-x64";
        };
      };

      plat =
        platforms.${system}
          or (throw "vscodeRemote: no remote-server artifacts for ${system} (linux hosts only)");

      # sha256 per commit, per artifact.
      hashes = {
        "8a7abeba6e03ea3af87bfbce9a1b7e48fed567b8" = {
          server-linux-arm64 = "sha256-sHHHf55lTnAFqtRITrNHEl1GXeP/00Cdyw8Vtlt8KmY=";
          cli-alpine-arm64 = "sha256-q9bp7zF76Oy74lWVS7duXBdPFeGzfPmdgqPVm3mIEqY=";
        };
      };

      pinned = hashes.${rev} or { };
      havePins = (pinned.${plat.server} or null) != null && (pinned.${plat.cli} or null) != null;

      # A nixpkgs bump moves `rev` ahead of these hashes. That WARNS and degrades to "VS Code downloads it
      # itself", which is merely the status quo — deliberately not a `throw`, because the throw sits under
      # `home.file` and would make the operator's ENTIRE home unbuildable: no shell, no git, no editor, and
      # the natural place to do the catch-up work is the machine it just bricked. Loud and recoverable
      # beats fail-closed when the thing being protected is a download.
      staleWarning = ''
        vscodeRemote: no pinned hashes for VS Code ${pkgs.vscode.version} (commit ${rev}).
        The remote server will be DOWNLOADED (~635MB per home) until they are refreshed. No download needed
        to refresh them — the update service returns the digest in a header:
          for a in ${plat.server} ${plat.cli}; do
            curl -fsSI https://update.code.visualstudio.com/commit:${rev}/$a/stable | grep -i x-sha256
          done
          nix hash convert --hash-algo sha256 --to sri <hex>
        then add them under "${rev}" in modules/home/dev/vscode-remote.nix.
      '';

      hashFor = artifact: pinned.${artifact};

      fetch =
        artifact:
        pkgs.fetchurl {
          url = "https://update.code.visualstudio.com/commit:${rev}/${artifact}/stable";
          hash = hashFor artifact;
        };

      # Microsoft's binaries are used AS SHIPPED — `runCommand` runs no fixup/strip/patchelf phase at all
      # (stdenv's `genericBuild` returns early for `buildCommand`), which is what we want: they run via
      # nix-ld exactly as the downloaded copies did, and rewriting them would change bytes the client
      # negotiated for.
      unpack =
        name: artifact: extra:
        pkgs.runCommand "vscode-${name}-${rev}" {
          src = fetch artifact;
          nativeBuildInputs = [ pkgs.gnutar ];
        } extra;
    in
    rec {
      inherit rev;

      # The server tree. Placed at `<home>/.vscode-server/cli/servers/Stable-<rev>/server`, which is the
      # exact path the CLI's `target_dir.exists()` check consults.
      #
      # The layout check is NOT belt-and-braces. `tar --strip-components=1` against a flat tarball throws
      # everything away and still exits 0, and the CLI's gate only tests that the PARENT directory exists —
      # so a wrong-shaped tree is never re-downloaded and the editor stays broken with no recovery path.
      # Fail here, at build time, instead.
      server = unpack "server" plat.server ''
        mkdir -p "$out"
        tar -xf "$src" -C "$out" --strip-components=1
        for f in product.json node bin/code-server out/server-main.js; do
          [ -e "$out/$f" ] || { echo "vscodeRemote: unpacked server has no $f — artifact layout changed" >&2; exit 1; }
        done
      '';

      # The CLI. Placed at `<home>/.vscode-server/code-<rev>`, gated by `[ -f "$CLI_PATH" ]`.
      cli = unpack "cli" plat.cli ''
        mkdir -p "$TMPDIR/x"
        tar -xf "$src" -C "$TMPDIR/x"
        [ -f "$TMPDIR/x/code" ] || { echo "vscodeRemote: cli tarball has no ./code — artifact layout changed" >&2; exit 1; }
        install -Dm755 "$TMPDIR/x/code" "$out"
      '';

      # `home.file` entries placing the two artifacts where the bootstrap looks. Symlinks, so a home costs
      # ~0 bytes and every home shares one store path.
      #
      # `force`: a home that has ever connected already has REAL files at both paths — home-manager's
      # `checkLinkTargets` aborts the whole activation on those rather than replacing them. The CLI can
      # also reclaim either path later (`code prune` removes the server dir for any server it thinks is
      # stopped), so this must survive being clobbered, not just the first switch.
      serverFiles =
        lib.optionalAttrs (!havePins) (lib.warn staleWarning { })
        // lib.optionalAttrs havePins {
          ".vscode-server/code-${rev}" = {
            source = cliWrapper;
            force = true;
          };
          ".vscode-server/cli/servers/Stable-${rev}/server" = {
            source = server;
            force = true;
          };
        };

      # `$CLI_PATH` is a thin WRAPPER, not the binary. The bootstrap only tests `[ -f "$CLI_PATH" ]` and
      # then executes it, so a script is as valid here as the binary, and `exec … "$@"` preserves argv
      # exactly — including the `--version` the install path evaluates.
      #
      # Its whole job is to deny the CLI an update endpoint. On every connect the CLI unconditionally
      # starts an "agent host" supervisor (`ensure_supervisor_running`, called from
      # `cli/src/commands/tunnels.rs` before the workbench process exists, so no setting, flag or policy
      # reaches it — microsoft/vscode#328397) which fetches its OWN ~635MB server resolved to
      # channel-LATEST: a different commit from the editor, for a feature documented as opt-in.
      #
      # All three `UpdateService` methods — including `get_download_stream` — build their URL from
      # `get_update_endpoint()`, which honours this variable. So the supervisor starts, fails its version
      # resolve once, and downloads nothing. It then writes its own correct lockfile, so later connects
      # reuse it rather than retrying. Measured: one `warn`, no retry storm, zero children (so the
      # `code agent kill` → `kill_tree` path is a no-op), ~16MB idle.
      #
      # This is safe ONLY because the server and CLI are pinned above — that endpoint is the one the
      # editor server would otherwise be fetched from. If the hashes ever go stale, `serverFiles` is empty,
      # this wrapper is not placed at all, and VS Code downloads normally: the degradation is losing the
      # optimisation, never a broken editor.
      cliWrapper = pkgs.writeShellScript "vscode-cli-wrapper-${rev}" ''
        set -u
        export VSCODE_CLI_UPDATE_URL=http://127.0.0.1:1
        exec ${cli} "$@"
      '';
    };
}
