{ lib, ... }:
let
  # Newest first. Keep the previous commit until every cage has restarted, so the Mac and the servers can move
  # in either order without a download.
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

  hasHashes = plat: pin: pin.hashes ? ${plat.server} && pin.hashes ? ${plat.cli};
in
{
  # The fleet is aarch64-linux.
  flake.lib.vscodePlacedCommits = map (pin: pin.commit) (
    builtins.filter (hasHashes platforms.aarch64-linux) pins
  );

  # Remote-SSH downloads ~635MB of server into every home it connects to, and its install gates are existence
  # checks (`[ -f "$CLI_PATH" ]` for the CLI, `target_dir.exists()` for the server) — so placing both from the store
  # suppresses the download, one copy shared by all homes.
  #
  # The commits are declared rather than `pkgs.vscode.rev`: a server must match the Mac's client, and a cage home
  # is evaluated with its session's nixpkgs, which can carry any VS Code.
  flake.lib.vscodeRemote =
    pkgs:
    let
      inherit (pkgs.stdenv.hostPlatform) system;

      plat =
        platforms.${system}
          or (throw "vscodeRemote: no remote-server artifacts for ${system} (linux hosts only)");

      fetch =
        pin: artifact:
        pkgs.fetchurl {
          url = "https://update.code.visualstudio.com/commit:${pin.commit}/${artifact}/stable";
          hash = pin.hashes.${artifact};
        };

      # `runCommand` runs no fixup phase: the binaries stay as shipped and run via nix-ld, like downloaded copies.
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
          # The layout check is load-bearing: `--strip-components=1` on a flat tarball exits 0 with nothing kept,
          # and the CLI only tests that the parent dir exists, so a wrong tree would never be re-downloaded.
          server = unpack pin "server" plat.server ''
            mkdir -p "$out"
            tar -xf "$src" -C "$out" --strip-components=1
            for f in product.json node bin/code-server out/server-main.js; do
              [ -e "$out/$f" ] || { echo "vscodeRemote: unpacked server has no $f — artifact layout changed" >&2; exit 1; }
            done
          '';

          cli = unpack pin "cli" plat.cli ''
            mkdir -p "$TMPDIR/x"
            tar -xf "$src" -C "$TMPDIR/x"
            [ -f "$TMPDIR/x/code" ] || { echo "vscodeRemote: cli tarball has no ./code — artifact layout changed" >&2; exit 1; }
            install -Dm755 "$TMPDIR/x/code" "$out"
          '';

          # `force`: a home that ever connected has real files at these paths, which home-manager otherwise refuses
          # to replace, and `code prune` can delete them again later.
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

          # The CLI's agent-host supervisor fetches its own ~635MB server at channel-latest, a different commit from
          # the editor, and no setting turns it off (microsoft/vscode#328397). All three `UpdateService` methods build
          # their URL from `get_update_endpoint()`, which honours this variable, so pointing it nowhere stops that;
          # safe only because the editor's own server is placed above. No reaping needed: since 1.133.0 a registry
          # reuses one supervisor (the 1.129.1 pile-up, screwyprof/devbox#482, is gone).
          cliWrapper = pkgs.writeShellScript "vscode-cli-wrapper-${rev}" ''
            set -u
            export VSCODE_CLI_UPDATE_URL=http://127.0.0.1:1
            exec ${cli} "$@"
          '';
        };

      unhashed = builtins.filter (pin: !hasHashes plat pin) pins;
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
        map (pin: (forPin pin).files) (builtins.filter (hasHashes plat) pins)
      )) unhashed;
    };
}
