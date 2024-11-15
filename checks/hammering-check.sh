#!/usr/bin/env bash
set -euo pipefail

echo "=== nixpkgs-hammering Check Results ==="
echo ""

# Create output directory
mkdir -p $out/nix-support

# Get all attributes from the test file
attrs=$(nix-instantiate --eval -E "builtins.attrNames (import $testNix {})" | tr -d '[]"' | tr ',' ' ')

echo "Running nixpkgs-hammer with parameters: $attrs -f $testNix"

# Run hammering and filter out noise
nixpkgs-hammer -f "$testNix" $attrs 2>&1 | \
  grep -v "warning: creating directory '/homeless-shelter" | \
  grep -v "error: build log" | \
  grep -v "warning: unable to download" | \
  grep -v "notice: no-build-output" | \
  tee $out/hammer_output.txt

# Check for warnings and format output
if grep -q "warning:" $out/hammer_output.txt; then
  echo "⚠️  Warnings found"
  exit 1
else
  echo "✅ No issues found"
fi

# Cleanup
rm -rf "$HOME"

# Always create a new result to prevent caching
date > $out/timestamp