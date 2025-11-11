#!/usr/bin/env bats

@test "plugin suggests alias when running git status" {
    run env -i zsh -df -c '
        source alias-teacher.plugin.zsh
        alias GwS="git status"
        _check_aliases "git status" "git status"
        _flush_ysu_buffer
    '
    # Should suggest using GwS for git status
    [[ "$output" =~ "Found existing alias for \"git status\"" ]]
    [[ "$output" =~ "You should use: \"GwS\"" ]]
}

@test "plugin shows related aliases for git diff" {
    run env -i zsh -df -c '
        source alias-teacher.plugin.zsh
        alias gd="git diff"
        alias gdw="git diff --word-diff"
        alias gds="git diff --staged"
        YSU_MODE="BESTMATCH"
        _check_aliases "git diff --cached" "git diff --cached"
        _flush_ysu_buffer
    '
    # Should show gd alias and related aliases
    [[ "$output" =~ "Related aliases for \"git diff --cached\"" ]] || [[ "$output" =~ "Found existing alias" ]]
}

@test "hardcore mode blocks and shows warning" {
    run env -i zsh -df -c '
        source alias-teacher.plugin.zsh
        alias GwS="git status"
        YSU_HARDCORE=1
        _check_aliases "git status" "git status"
        _flush_ysu_buffer
    '
    # Should show hardcore message and exit with SIGINT (130)
    [[ "$output" =~ "hardcore mode enabled" ]]
    [[ "$status" -eq 130 ]]
}