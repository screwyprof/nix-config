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

      # `$CLI_PATH` is a WRAPPER, not the binary, purely to close a startup race.
      #
      # The decoy unit is `WantedBy=default.target`, and the operator has no lingering user manager (the
      # node's operator account is lima-provisioned, so it is not in `users.users` and NixOS cannot declare
      # `linger` for it). Without lingering the manager stops with the last session, so on the first
      # connect of a session `default.target` is still coming up asynchronously — and the CLI's
      # supervisor check can win that race, spawn a real supervisor, and fetch the 635MB server before the
      # lockfile exists.
      #
      # Starting the unit here puts the guarantee on the CONNECT path, where it is ordered rather than
      # raced: `systemctl --user start` blocks until the job completes, so the lockfile is on disk before
      # the CLI runs. Already-running is a no-op. `--user` needs only `XDG_RUNTIME_DIR` (it talks to the
      # manager's private socket, not the session bus).
      #
      # Failure degrades rather than breaks: if the unit cannot start, the CLI spawns its own supervisor
      # and downloads, which is the status quo. The bootstrap only tests `[ -f "$CLI_PATH" ]` and then
      # executes it, so a script is as valid here as the binary, and `exec … "$@"` preserves argv exactly
      # — including the `--version` the install path invokes.
      cliWrapper = pkgs.writeShellScript "vscode-cli-wrapper-${rev}" ''
        set -u
        : "''${XDG_RUNTIME_DIR:=/run/user/$(${pkgs.coreutils}/bin/id -u)}"
        export XDG_RUNTIME_DIR
        ${pkgs.systemd}/bin/systemctl --user start vscode-agent-host-decoy.service 2>/dev/null || true
        exec ${cli} "$@"
      '';

      # The no-op agent-host supervisor, and the lockfile that points at it.
      #
      # WHY: on every connect the CLI unconditionally starts an "agent host" supervisor, which downloads
      # its own ~635MB server resolved to channel-LATEST — a different commit from the editor, for a
      # feature documented as opt-in. Nothing disables it: `ensure_supervisor_running` is called
      # unconditionally from `cli/src/commands/tunnels.rs`, before the workbench process exists, so no
      # setting, flag, env var or enterprise policy reaches it. Reported as microsoft/vscode#328397.
      #
      # HOW: the CLI reuses any lockfile that parses and whose pid is ALIVE — it never dials the port and
      # never checks the process is really a supervisor. So a real, childless, do-nothing process is
      # enough, and the lockfile then states the truth rather than a convenient fiction.
      #
      # NOT pid 1. `code agent kill` and `code agent host --replace` both feed the recorded pid straight
      # into `kill_tree`, which walks `pgrep -P` descendants and SIGTERMs the lot. Rooted at pid 1 that is
      # every process the operator owns — and the CLI's own reuse banner advertises `code agent kill`.
      # Pointed at this unit it is a no-op: `sleep` has no children, and systemd restarts it.
      #
      # port 0 is deliberately unconnectable. The CLI passes the recorded host/port into the spawned
      # server as `--agent-host-bridge-port`, so the bridge is configured but always fails to dial —
      # rather than pointing at a low port something else could bind.
      agentHostDecoy = {
        systemd.user.services.vscode-agent-host-decoy = {
          Unit.Description = "Placeholder VS Code agent-host supervisor (suppresses the channel-latest server download)";
          Install.WantedBy = [ "default.target" ];
          Service = {
            Type = "simple";
            Restart = "always";
            ExecStart = toString (
              pkgs.writeShellScript "vscode-agent-host-decoy" ''
                set -eu
                lock="$HOME/.vscode-server/cli/agent-host-stable.lock"
                mkdir -p "$(dirname "$lock")"
                printf '{"schemaVersion":1,"pid":%d,"port":0,"protocolVersion":"0.1.0"}\n' "$$" > "$lock"
                exec ${pkgs.coreutils}/bin/sleep infinity
              ''
            );
            ExecStopPost = toString (
              pkgs.writeShellScript "vscode-agent-host-decoy-stop" ''
                rm -f "$HOME/.vscode-server/cli/agent-host-stable.lock"
              ''
            );
          };
        };
      };
    };
}
