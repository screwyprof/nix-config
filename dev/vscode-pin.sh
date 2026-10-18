# Pin the VS Code server + CLI for the Mac's client (newest first), or `--prune` to that client's pin only.
root=$(git rev-parse --show-toplevel)
file="$root/modules/home/dev/_vscode-pins.nix"
# Captured into variables, never `< <(…)`: errexit cannot see a failing process substitution.
artifacts_json=$(nix eval --json "$root#lib.vscodeFleetArtifacts")
mapfile -t artifacts < <(jq -r '.[]' <<<"$artifacts_json")
if ((${#artifacts[@]} == 0)); then
  echo "vscode-pin: lib.vscodeFleetArtifacts is empty" >&2
  exit 1
fi
trap 'rm -f "$file.tmp"' EXIT

write() {
  {
    echo '# Maintained by vscode-pin (dev shell) — newest first. Hand edits survive only until its next run.'
    nix-instantiate --eval --strict --argstr j "$1" --expr '{ j }: builtins.fromJSON j' | nixfmt -
  } >"$file.tmp"
  mv "$file.tmp" "$file"
  git -C "$root" --no-pager diff HEAD -- "$file"
  echo "vscode-pin: $2 — not committed; review the diff above. Deploy order: DECISIONS 012."
}

current=$(nix eval --json --file "$file")
client=$(nix eval --raw \
  "$root#darwinConfigurations.macbook.config.home-manager.users.happygopher.programs.vscode.package" \
  --apply 'p: p.version + " " + p.rev')
read -r version commit <<<"$client"


case "${1:-}" in
  --prune)
    if ! jq -e --arg c "$commit" 'any(.commit == $c)' <<<"$current" >/dev/null; then
      echo "vscode-pin: the Mac's VS Code $version ($commit) is not pinned; nothing to keep" >&2
      exit 1
    fi
    write "$(jq --arg c "$commit" 'map(select(.commit == $c))' <<<"$current")" "kept only VS Code $version, the Mac's client"
    exit 0
    ;;
  "") ;;
  *)
    echo "usage: vscode-pin [--prune]" >&2
    exit 2
    ;;
esac

# The module's own rule for "pinned" (a commit with every fleet artifact hashed), shared with the Mac's assertion.
placed=$(nix eval --json "$root#lib.vscodePlacedCommits")
if jq -e --arg c "$commit" 'any(. == $c)' <<<"$placed" >/dev/null; then
  echo "vscode-pin: VS Code $version ($commit) is already pinned"
  exit 0
fi

# No download: the update service returns each artifact's digest in a HEAD header.
hashes=()
for a in "${artifacts[@]}"; do
  hex=$(curl -fsSI -o /dev/null -w '%header{x-sha256}' "https://update.code.visualstudio.com/commit:$commit/$a/stable")
  if ! [[ $hex =~ ^[0-9a-f]{64}$ ]]; then
    echo "vscode-pin: no x-sha256 for $a at $commit" >&2
    exit 1
  fi
  hashes+=(--arg "$a" "$(nix hash convert --hash-algo sha256 --to sri "$hex")")
done

write "$(jq --arg v "$version" --arg c "$commit" --argjson h "$(jq -n "${hashes[@]}" '$ARGS.named')" \
  '[{ version: $v, commit: $c, hashes: $h }] + map(select(.commit != $c))' <<<"$current")" "pinned VS Code $version ($commit)"
