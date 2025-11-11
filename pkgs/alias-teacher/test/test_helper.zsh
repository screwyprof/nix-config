#!/usr/bin/env zsh

# Clean test shell command used across all tests
TEST_SHELL="env -i TERM=xterm zsh -df -c"

# Common setup function for hardcore ALL mode testing
# Baseline configuration: YSU_VERSION=2.0.0, YSU_MODE=ALL, YSU_HARDCORE=1, YSU_MESSAGE_POSITION=after
setup_hardcore_all_mode() {
    source alias-teacher.plugin.zsh
    export YSU_VERSION="2.0.0"
    export YSU_MODE="ALL"
    export YSU_HARDCORE=1
    export YSU_MESSAGE_POSITION="after"
    # Override hardcore kill for testing
    _check_ysu_hardcore() { _write_ysu_buffer "${BOLD}${RED}You Should Use hardcore mode enabled. Use your aliases!${NONE}\n"; }
}

# Setup common git aliases used across most tests
setup_common_git_aliases() {
    alias G="git"

    # Git status aliases
    alias GwS="git status"
    alias Gws="git status --short --branch"
    alias Gdi="git status --porcelain --ignored=matching | sed -n 's/^!! //p'"

    # Git diff aliases
    alias Gwd="git diff --no-ext-diff"
    alias GwD="git diff --no-ext-diff --word-diff"
    alias GiD="git diff --no-ext-diff --cached --word-diff"
    alias Gid="git diff --no-ext-diff --cached"
}