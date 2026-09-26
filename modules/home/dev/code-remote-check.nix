{
  # `code` for REMOTE opens: before launching, check that the remote home already has a server for THIS
  # client's commit. Remote-SSH otherwise downloads one (~1.3 GB) into that home, silently. The client is
  # the only source of truth for the commit; the remote's nixpkgs need not match it.
  #
  # `ssh` is whatever is on PATH, not a pinned one: it must read `~/.ssh/config` the way Remote-SSH does
  # (Apple's ssh accepts `UseKeychain`, nixpkgs' rejects it).
  flake.lib.codeRemoteCheck =
    pkgs: realCode:
    pkgs.writeShellApplication {
      name = "code";
      text = ''
        real=${realCode}

        # An authority is `ssh-remote+<alias>`, `+` possibly as %2B, or `ssh-remote+<hex of JSON>` for aliases
        # VS Code cannot spell plainly (Remote Explorer, recent hosts).
        host_of() {
          local a=''${1#vscode-remote://}
          a=''${a%%/*}
          a=''${a/\%2[Bb]/+}
          case "$a" in ssh-remote+*) a=''${a#ssh-remote+} ;; *) return 1 ;; esac
          if [[ $a =~ ^7b([0-9a-f][0-9a-f])+$ ]]; then
            local json="" c i
            for ((i = 0; i < ''${#a}; i += 2)); do
              printf -v c '%b' "\\x''${a:i:2}"
              json+=$c
            done
            a=""
            if [[ $json =~ \"hostName\":\"([^\"]*)\" ]]; then
              a=''${BASH_REMATCH[1]}
            fi
          fi
          [ -n "$a" ] && printf '%s\n' "$a"
        }

        hosts=()
        prev=""
        for arg in "$@"; do
          value=""
          case "$prev" in --remote | --folder-uri | --file-uri) value=$arg ;; esac
          case "$arg" in --remote=* | --folder-uri=* | --file-uri=*) value=''${arg#*=} ;; esac
          if [ -n "$value" ] && host=$(host_of "$value"); then
            hosts+=("$host")
          fi
          prev=$arg
        done

        if [ ''${#hosts[@]} -eq 0 ] || [ -n "''${CODE_REMOTE_ALLOW_DOWNLOAD:-}" ]; then
          exec "$real" "$@"
        fi

        version=$("$real" --version) || exec "$real" "$@"
        commit=''${version#*$'\n'}
        commit=''${commit%%$'\n'*}
        if ! [[ $commit =~ ^[0-9a-f]{40}$ ]]; then
          exec "$real" "$@"
        fi

        missing=()
        for host in "''${hosts[@]}"; do
          if [[ $host == -* ]]; then
            echo "code: refusing remote host '$host'." >&2
            exit 1
          fi
          answer=$(ssh -o BatchMode=yes -o ConnectTimeout=10 -- "$host" \
            "if test -x ~/.vscode-server/cli/servers/Stable-$commit/server/bin/code-server; then echo present; else echo absent; fi" \
            </dev/null 2>/dev/null) || true
          answer=''${answer##*$'\n'}
          case "$answer" in
            present) ;;
            absent) missing+=("$host") ;;
            *) echo "code: could not check '$host' for a placed server; opening anyway." >&2 ;;
          esac
        done
        if [ ''${#missing[@]} -eq 0 ]; then
          exec "$real" "$@"
        fi

        msg="code: no VS Code server for this client (''${version%%$'\n'*}, ''${commit:0:7}) on: ''${missing[*]} — opening downloads one (~1.3 GB) into each home."
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
