{ lib, ... }:
let
  # Newest first.
  pins = [
    {
      version = "1.139.1";
      commit = "04c0d99f4fb0d8afe6ce4f0c58e31e183ac3e4b1";
      hashes = {
        server-linux-arm64 = "sha256-v/SzY7hIIFXfg9jmifRVmJrdX+gW9UOW5RfTLf9bisI=";
        cli-alpine-arm64 = "sha256-8HO6UuChUUaMdhskF5P4pJWqXsIVNOdx2Ns1Fd1H2B4=";
      };
    }
  ];
in
{
  flake.lib.vscodeServerPins = pins;

  # The VS Code REMOTE server + CLI, fetched from Microsoft and pinned.
  #
  # Remote-SSH downloads ~635MB of server into every remote `$HOME` it connects to, and the install gates
  # are pure existence checks — `[ -f "$CLI_PATH" ]` for the CLI, `target_dir.exists()` for the server. So
  # placing these from the store suppresses both downloads entirely: one copy per commit, shared by every
  # home, instead of one copy per home.
  #
  # THE COMMITS ARE DECLARED, NOT DERIVED. A server must match the CLIENT, and the client is the Mac's; a cage home
  # is evaluated with its SESSION's nixpkgs (`operator.inputs.nixpkgs.follows`), so `pkgs.vscode.rev` there named
  # whatever VS Code that session happened to lock. `checks.vscode-client-pinned` keeps the Mac's commit in `pins`.
  #
  # Upgrade without a download: add the new commit FIRST (keep the old), `vm apply`, let cages `up`, then move the
  # Mac, then drop the old one.
  #
  # Refresh a hash WITHOUT downloading — the update service returns the digest in a HEAD header:
  #   curl -fsSI https://update.code.visualstudio.com/commit:<rev>/<platform>/stable | grep -i x-sha256
  #   nix hash convert --hash-algo sha256 --to sri <hex>
  flake.lib.vscodeRemote =
    pkgs:
    let
      inherit (pkgs.stdenv.hostPlatform) system;

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

      fetch =
        pin: artifact:
        pkgs.fetchurl {
          url = "https://update.code.visualstudio.com/commit:${pin.commit}/${artifact}/stable";
          hash = pin.hashes.${artifact};
        };

      # Microsoft's binaries are used AS SHIPPED — `runCommand` runs no fixup/strip/patchelf phase at all
      # (stdenv's `genericBuild` returns early for `buildCommand`), which is what we want: they run via
      # nix-ld exactly as the downloaded copies did, and rewriting them would change bytes the client
      # negotiated for.
      unpack =
        pin: name: artifact: extra:
        pkgs.runCommand "vscode-${name}-${pin.commit}" {
          src = fetch pin artifact;
          nativeBuildInputs = [ pkgs.gnutar ];
        } extra;

      forPin =
        pin:
        let
          rev = pin.commit;
        in
        rec {

          # The server tree. Placed at `<home>/.vscode-server/cli/servers/Stable-<rev>/server`, which is the
          # exact path the CLI's `target_dir.exists()` check consults.
          #
          # The layout check is NOT belt-and-braces. `tar --strip-components=1` against a flat tarball throws
          # everything away and still exits 0, and the CLI's gate only tests that the PARENT directory exists —
          # so a wrong-shaped tree is never re-downloaded and the editor stays broken with no recovery path.
          # Fail here, at build time, instead.
          server = unpack pin "server" plat.server ''
            mkdir -p "$out"
            tar -xf "$src" -C "$out" --strip-components=1
            for f in product.json node bin/code-server out/server-main.js; do
              [ -e "$out/$f" ] || { echo "vscodeRemote: unpacked server has no $f — artifact layout changed" >&2; exit 1; }
            done
          '';

          # The CLI. Placed at `<home>/.vscode-server/code-<rev>`, gated by `[ -f "$CLI_PATH" ]`.
          cli = unpack pin "cli" plat.cli ''
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
          files = {
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
          # Its whole job is to deny the CLI an update endpoint. The CLI starts an "agent host" supervisor
          # which fetches its OWN ~635MB server resolved to channel-LATEST — a different commit from the
          # editor, for a feature documented as opt-in. All three `UpdateService` methods, including
          # `get_download_stream`, build their URL from `get_update_endpoint()`, which honours this variable,
          # so the supervisor starts, fails its version resolve once, and downloads nothing.
          #
          # WHAT CHANGED IN 1.133.0, because the previous version of this comment is now wrong in two places
          # and both were load-bearing. It said the spawn is UNCONDITIONAL and that "no setting, flag or
          # policy reaches it (microsoft/vscode#328397)": in 1.133.0 `ensure_supervisor_running` sits behind a
          # LAZY future whose own comment says "a tunnel that nobody connects to must not spawn a standalone
          # supervisor by itself", with the protocol-v6 route consulting the registry directly. And it said
          # the supervisor "writes its own correct lockfile": 1.129.1 kept that at
          # `.vscode-server/cli/agent-host-<quality>.lock`, and 1.133.0 replaced it with a REGISTRY of
          # `entries/<sha256>.json` under `resolve_user_data_path()` — on Linux `~/.config/Code/agent-host/`,
          # a tree neither this module nor home-manager touches. A leftover 1.129.1 lockfile is inert debris.
          #
          # THAT REPLACEMENT FIXED AN ACCUMULATION BUG, and it is worth recording because devbox chased it for
          # a day. Under 1.129.1 a stale lockfile classified as `SpawnFresh` on every connect, so supervisors
          # piled up — screwyprof/devbox#482 measured 6 against 1 lockfile, one of them 18 days old. Measured
          # on 1.133.0 from a nuked `.vscode-server` AND a nuked registry, vanilla wrapper, three connects with
          # disconnects: ONE supervisor, ONE registry entry naming it (`type=standalone`). The registry reuse
          # works, so nothing here needs to reap anything — an earlier attempt to add `agent kill` to this
          # wrapper was withdrawn for exactly that reason.
          #
          # This is safe ONLY because the server and CLI are pinned above — that endpoint is the one the
          # editor server would otherwise be fetched from. A pin without this platform's hashes is not placed,
          # wrapper included, and VS Code downloads normally: the degradation is losing the optimisation, never
          # a broken editor.
          cliWrapper = pkgs.writeShellScript "vscode-cli-wrapper-${rev}" ''
            set -u
            export VSCODE_CLI_UPDATE_URL=http://127.0.0.1:1
            exec ${cli} "$@"
          '';
        };

      hasHashes = pin: pin.hashes ? ${plat.server} && pin.hashes ? ${plat.cli};
      unhashed = builtins.filter (pin: !hasHashes pin) pins;
      warnUnhashed =
        pin:
        lib.warn ''
          vscodeRemote: VS Code ${pin.version} (${pin.commit}) has no ${system} hashes, so it is not placed and
          Remote-SSH will download it (~635MB per home). No download needed to fill them in:
            for a in ${plat.server} ${plat.cli}; do
              curl -fsSI https://update.code.visualstudio.com/commit:${pin.commit}/$a/stable | grep -i x-sha256
            done
            nix hash convert --hash-algo sha256 --to sri <hex>
        '';
    in
    {
      serverFiles = lib.foldr warnUnhashed (lib.mergeAttrsList (
        map (pin: (forPin pin).files) (builtins.filter hasHashes pins)
      )) unhashed;
    };
}
