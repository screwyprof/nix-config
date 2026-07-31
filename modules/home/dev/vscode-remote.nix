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
  # and a bump without a matching entry FAILS EVAL rather than silently regressing to downloading — which
  # is the whole point of keying them by rev.
  #
  # Refresh a hash WITHOUT downloading — the update service returns it in a HEAD header:
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

      # sha256 per commit, per artifact. Missing entry => eval failure, by design.
      hashes = {
        "8a7abeba6e03ea3af87bfbce9a1b7e48fed567b8" = {
          server-linux-arm64 = "sha256-sHHHf55lTnAFqtRITrNHEl1GXeP/00Cdyw8Vtlt8KmY=";
          cli-alpine-arm64 = "sha256-q9bp7zF76Oy74lWVS7duXBdPFeGzfPmdgqPVm3mIEqY=";
        };
      };

      hashFor =
        artifact:
        hashes.${rev}.${artifact} or (throw ''
          vscodeRemote: no pinned hash for ${artifact} at commit ${rev} (VS Code ${pkgs.vscode.version}).

          nixpkgs moved the editor and this pin has not caught up. Refresh without downloading:
            curl -fsSI https://update.code.visualstudio.com/commit:${rev}/${artifact}/stable | grep -i x-sha256
            nix hash convert --hash-algo sha256 --to sri <hex>
          then add it under "${rev}" in modules/home/dev/vscode-remote.nix.
        '');

      fetch =
        artifact:
        pkgs.fetchurl {
          url = "https://update.code.visualstudio.com/commit:${rev}/${artifact}/stable";
          hash = hashFor artifact;
        };

      # Microsoft's binaries are used AS SHIPPED — no patchelf, no stripping. They run via nix-ld, which is
      # what the remote already relies on today; fixing them up here would change bytes the client expects.
      unpack =
        name: artifact: extra:
        pkgs.runCommand "vscode-${name}-${rev}" {
          src = fetch artifact;
          nativeBuildInputs = [ pkgs.gnutar ];
          dontFixup = true;
        } extra;
    in
    rec {
      inherit rev;

      # The server tree. Placed at `<home>/.vscode-server/cli/servers/Stable-<rev>/server`, which is the
      # exact path the CLI's `target_dir.exists()` check consults.
      server = unpack "server" plat.server ''
        mkdir -p "$out"
        tar -xf "$src" -C "$out" --strip-components=1
      '';

      # The CLI. Placed at `<home>/.vscode-server/code-<rev>`, gated by `[ -f "$CLI_PATH" ]`.
      cli = unpack "cli" plat.cli ''
        mkdir -p "$TMPDIR/x"
        tar -xf "$src" -C "$TMPDIR/x"
        install -Dm755 "$TMPDIR/x/code" "$out"
      '';

      # `home.file` entries placing everything where the bootstrap looks. Symlinks, so a home costs ~0
      # bytes and every home shares one store path.
      serverFiles = {
        ".vscode-server/code-${rev}".source = cli;
        ".vscode-server/cli/servers/Stable-${rev}/server".source = server;

        # Suppresses the SECOND server. On every connect the CLI unconditionally starts an "agent host"
        # supervisor, which downloads its own ~635MB server resolved to channel-LATEST — a different
        # commit from the editor, for a feature documented as opt-in. No setting, flag, env var or
        # enterprise policy disables it: `ensure_supervisor_running` is called unconditionally from
        # `cli/src/commands/tunnels.rs`, and it runs before the workbench process exists, so no workbench
        # setting can gate it. Reported upstream as microsoft/vscode#328397.
        #
        # The CLI reuses any lockfile that parses and whose pid is alive — it never dials the port and
        # never checks the process is really a supervisor. Naming pid 1 therefore reads as "already
        # running", so none is started and nothing is fetched. The renderer just does not get
        # `agentHostProxy`, which upstream already treats as a benign degraded path (a `warning!`, and the
        # server starts regardless).
        ".vscode-server/cli/agent-host-stable.lock".text = builtins.toJSON {
          schemaVersion = 1;
          pid = 1;
          port = 1;
          protocolVersion = "0.1.0";
        };
      };
    };
}
