# Pin the VS Code server + CLI for the Mac's client (newest first), or `--prune` to the newest pin only.
root=$(git rev-parse --show-toplevel)
file="$root/modules/home/dev/_vscode-pins.nix"
mapfile -t artifacts < <(nix eval --json "$root#lib.vscodeFleetArtifacts" | jq -r '.[]')

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

case "${1:-}" in
  --prune)
    write "$(jq '.[:1]' <<<"$current")" "kept only VS Code $(jq -r '.[0].version' <<<"$current")"
    exit 0
    ;;
  "") ;;
  *)
    echo "usage: vscode-pin [--prune]" >&2
    exit 2
    ;;
esac

read -r version commit <<<"$(nix eval --raw \
  "$root#darwinConfigurations.macbook.config.home-manager.users.happygopher.programs.vscode.package" \
  --apply 'p: p.version + " " + p.rev')"

if jq -e --arg c "$commit" 'any(.commit == $c)' <<<"$current" >/dev/null; then
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
  '[{ version: $v, commit: $c, hashes: $h }] + .' <<<"$current")" "pinned VS Code $version ($commit)"
