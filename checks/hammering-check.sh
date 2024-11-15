#!/usr/bin/env bash
set -euo pipefail
              
# Run hammering and capture output
nixpkgs-hammer -f $testNix mysides 2>&1 | \
  grep -v "warning: creating directory '/homeless-shelter" | \
  grep -v "error: build log" | \
  grep -v "notice: no-build-output" > hammer_output.txt

# Create output directory
mkdir -p $out

# Extract and format warnings
{
  echo "=== nixpkgs-hammering Check Results ==="
  echo ""
    
  if grep -q "warning:" hammer_output.txt; then
    echo "⚠️  Warnings found:"
    echo "----------------------------------------"
    grep -A2 "warning:" hammer_output.txt | grep -v "See:"
    echo "----------------------------------------"
    echo ""
    echo "For details, see:"
    grep "See:" hammer_output.txt
      
    # Save full output
    mkdir -p $out/nix-support
    cp hammer_output.txt $out/nix-support/
      
    # Exit with error to indicate warnings were found
    exit 1
  else
    echo "✅ No issues found"
  fi
} | tee $out/result.txt

# Always create a new result to prevent caching
date > $out/timestamp