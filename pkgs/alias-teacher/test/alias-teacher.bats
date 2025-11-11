#!/usr/bin/env bats

# Baseline configuration: YSU_VERSION=2.0.0, YSU_MODE=ALL, YSU_HARDCORE=1, YSU_MESSAGE_POSITION=after

@test "basic alias suggestion for git status" {
    run env -i TERM=xterm zsh -df -c '
        source alias-teacher.plugin.zsh
        alias GwS="git status"
        export YSU_VERSION="2.0.0"
        export YSU_MODE="ALL"
        export YSU_HARDCORE=1
        export YSU_MESSAGE_POSITION="after"
        _check_ysu_hardcore() { _write_ysu_buffer "${BOLD}${RED}You Should Use hardcore mode enabled. Use your aliases!${NONE}\n"; }
        _check_aliases "git status" "git status"
        _flush_ysu_buffer
    '
    echo "$output" | grep -q "Found existing alias for.*git status"
    echo "$output" | grep -q "You should use:.*GwS"
}

@test "git diff command shows related aliases" {
    run env -i TERM=xterm zsh -df -c '
        source alias-teacher.plugin.zsh
        alias G="git"
        alias Gwd="git diff --no-ext-diff"
        alias GiD="git diff --no-ext-diff --cached --word-diff"
        export YSU_VERSION="2.0.0"
        export YSU_MODE="ALL"
        export YSU_HARDCORE=1
        export YSU_MESSAGE_POSITION="after"
        _check_ysu_hardcore() { _write_ysu_buffer "${BOLD}${RED}You Should Use hardcore mode enabled. Use your aliases!${NONE}\n"; }
        _check_aliases "git diff" "git diff"
        _flush_ysu_buffer
    '
    echo "$output" | grep -q "Found existing alias for.*git"
    echo "$output" | grep -q "Related aliases for.*git diff"
    echo "$output" | grep -q "Gwd.*git.*diff" || echo "$output" | grep -q "Gwd:"
    echo "$output" | grep -q "GiD.*git.*diff" || echo "$output" | grep -q "GiD:"
}

@test "git diff --cached shows only cached-related aliases" {
    run env -i TERM=xterm zsh -df -c '
        source alias-teacher.plugin.zsh
        alias G="git"
        alias Gwd="git diff --no-ext-diff"                     # Should NOT show
        alias GwD="git diff --no-ext-diff --word-diff"          # Should NOT show
        alias GiD="git diff --no-ext-diff --cached --word-diff" # Should show
        alias Gid="git diff --no-ext-diff --cached"            # Should show
        export YSU_VERSION="2.0.0"
        export YSU_MODE="ALL"
        export YSU_HARDCORE=1
        export YSU_MESSAGE_POSITION="after"
        _check_ysu_hardcore() { _write_ysu_buffer "${BOLD}${RED}You Should Use hardcore mode enabled. Use your aliases!${NONE}\n"; }
        _check_aliases "git diff --cached" "git diff --cached"
        _flush_ysu_buffer
    '

    # This test FAILS until the bug is fixed - it should NOT find Gwd and GwD
    echo "$output" | grep -q "Gwd" && echo "❌ Found Gwd (should not be there)" && exit 1
    echo "$output" | grep -q "GwD" && echo "❌ Found GwD (should not be there)" && exit 1
    echo "$output" | grep -q "Gid" || { echo "❌ Missing Gid"; exit 1; }
    echo "$output" | grep -q "GiD" || { echo "❌ Missing GiD"; exit 1; }
}