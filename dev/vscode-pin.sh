# Pin the VS Code server + CLI for the Mac's client (newest first), or `--prune` to the newest pin only.
root=$(git rev-parse --show-toplevel)
file="$root/modules/home/dev/_vscode-pins.nix"
artifacts=(server-linux-arm64 cli-alpine-arm64) # the fleet is aarch64-linux

# Nix reads and writes the file: JSON only in transit, so the repo keeps a plain Nix list.
write() {
  local dir
  dir=$(mktemp -d)
  printf '%s\n' "$1" >"$dir/pins.json"
  {
    # shellcheck disable=SC2016 # literal backticks in the file header
    echo '# Maintained by `vscode-pin` (dev shell) — newest first. Hand edits survive only until its next run.'
    nix-instantiate --eval --strict --expr "builtins.fromJSON (builtins.readFile $dir/pins.json)" | nixfmt -
  } >"$dir/pins.nix"
  nix eval --json --file "$dir/pins.nix" >/dev/null
  mv "$dir/pins.nix" "$file"
  rm -rf "$dir"
  # Never commits: show what changed since the last commit; the operator reviews and commits.
  git -C "$root" --no-pager diff HEAD -- "$file"
}

current=$(nix eval --json --file "$file")

case "${1:-}" in
  --prune)
    write "$(jq '.[:1]' <<<"$current")"
    echo "vscode-pin: kept only VS Code $(jq -r '.[0].version' <<<"$current") — not committed; review the diff above."
    exit 0
    ;;
  "") ;;
  *)
    echo "usage: vscode-pin [--prune]" >&2
    exit 2
    ;;
esac

# shellcheck disable=SC2016 # a Nix expression: its ${…} is Nix's, not the shell's
# Captured first: `--raw` prints no trailing newline, and `read` returning 1 at EOF would end the script silently.
client=$(nix eval --raw \
  "$root#darwinConfigurations.macbook.config.home-manager.users.happygopher.programs.vscode.package" \
  --apply 'p: "${p.version} ${p.rev}"')
read -r version commit <<<"$client"

if jq -e --arg c "$commit" 'any(.[]; .commit == $c)' <<<"$current" >/dev/null; then
  echo "vscode-pin: VS Code $version ($commit) is already pinned"
  exit 0
fi

# No download: the update service returns each artifact's digest in a HEAD header.
hashes='{}'
for a in "${artifacts[@]}"; do
  hex=$(curl -fsSI "https://update.code.visualstudio.com/commit:$commit/$a/stable" |
    tr -d '\r' | awk 'tolower($1) == "x-sha256:" { print $2 }')
  if ! [[ $hex =~ ^[0-9a-f]{64}$ ]]; then
    echo "vscode-pin: no x-sha256 for $a at $commit" >&2
    exit 1
  fi
  sri=$(nix hash convert --hash-algo sha256 --to sri "$hex")
  hashes=$(jq --arg a "$a" --arg s "$sri" '. + {($a): $s}' <<<"$hashes")
done

write "$(jq --arg v "$version" --arg c "$commit" --argjson h "$hashes" \
  '[{ version: $v, commit: $c, hashes: $h }] + .' <<<"$current")"
echo "vscode-pin: pinned VS Code $version ($commit) — not committed; review the diff above."
echo "Then: commit; vm apply + down/up the cages; THEN rebuild the Mac; later \`vscode-pin --prune\`."
