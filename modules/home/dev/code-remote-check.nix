{
  # `code` for REMOTE opens: before launching, check that the remote home already has a server for THIS
  # client's commit. Remote-SSH otherwise downloads one (~1.3 GB) into that home, silently. The client is
  # the only source of truth for the commit; the remote's nixpkgs need not match it.
  flake.lib.codeRemoteCheck =
    pkgs: realCode:
    pkgs.writeShellApplication {
      name = "code";
      runtimeInputs = [ pkgs.openssh ];
      text = ''
        real=${realCode}

        remote=""
        prev=""
        for arg in "$@"; do
          case "$prev" in --remote | --folder-uri | --file-uri) remote=$arg ;; esac
          case "$arg" in --remote=* | --folder-uri=* | --file-uri=*) remote=''${arg#*=} ;; esac
          prev=$arg
        done
        remote=''${remote#vscode-remote://}
        case "$remote" in
          ssh-remote+*) host=''${remote#ssh-remote+} host=''${host%%/*} ;;
          *) exec "$real" "$@" ;;
        esac

        if [ -n "''${CODE_REMOTE_ALLOW_DOWNLOAD:-}" ]; then
          exec "$real" "$@"
        fi

        version=$("$real" --version)
        commit=$(sed -n 2p <<<"$version")
        if ! [[ $commit =~ ^[0-9a-f]{40}$ ]]; then
          exec "$real" "$@"
        fi

        rc=0
        ssh -o BatchMode=yes -o ConnectTimeout=10 "$host" \
          "test -x ~/.vscode-server/cli/servers/Stable-$commit/server/bin/code-server" </dev/null >/dev/null 2>&1 || rc=$?
        case $rc in
          0) exec "$real" "$@" ;;
          1) ;;
          *)
            echo "code: could not check '$host' for a placed server (ssh exit $rc); opening anyway." >&2
            exec "$real" "$@"
            ;;
        esac

        msg="code: '$host' has no VS Code server for this client ($(head -1 <<<"$version"), ''${commit:0:7}) — opening downloads one (~1.3 GB) into that home."
        if [ -t 0 ] && [ -t 2 ]; then
          printf '%s\nOpen anyway? [y/N] ' "$msg" >&2
          read -r answer || answer=""
          case "$answer" in
            y | Y | yes | YES) exec "$real" "$@" ;;
          esac
          exit 1
        fi
        echo "$msg Set CODE_REMOTE_ALLOW_DOWNLOAD=1 to open anyway." >&2
        exit 1
      '';
    };
}
