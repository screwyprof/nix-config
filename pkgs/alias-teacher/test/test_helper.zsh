#!/usr/bin/env zsh

# Clean test shell command used across all tests
TEST_SHELL="env -i TERM=xterm zsh -df -c"

# Common setup function for hardcore ALL mode testing
# Baseline configuration: YSU_VERSION=2.0.0, YSU_SHOW_RECOMMENDED=1, YSU_HARDCORE=1, YSU_MESSAGE_POSITION=after
setup_hardcore_all_mode() {
    source alias-teacher.plugin.zsh
    export YSU_VERSION="2.0.0"
    export YSU_SHOW_RECOMMENDED=1
    export YSU_HARDCORE=1
    export YSU_MESSAGE_POSITION="after"
    # Override hardcore kill for testing
    _enforce_harcore_mode() { _write_ysu_buffer "${BOLD}${RED}You Should Use hardcore mode enabled. Use your aliases!${NONE}\n"; }
}

# Setup common git aliases used across most tests
setup_common_git_aliases() {
    # Define git log format variables (properly escaped for copy-paste)
    _git_log_fuller_format='%C(bold yellow)commit %H%C(auto)%d%n%C(bold)Author: %C(blue)%an <%ae> %C(cyan)%ai (%ar)%n%C(bold)Commit: %C(blue)%cn <%ce> %C(cyan)%ci (%cr)%C(reset)%n%+B'
    _git_log_oneline_format='%C(bold yellow)%h%C(reset) %s%C(auto)%d%C(reset)'
    _git_log_oneline_medium_format='%C(bold yellow)%h%C(reset) %<(50,trunc)%s %C(bold blue)%an %C(cyan)%as (%ar)%C(auto)%d%C(reset)'

    # Git alias
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

    # Git log aliases (unique names for testing - using real git format strings)
    alias Gl="git log --date-order --pretty=format:$_git_log_fuller_format"
    alias Glo="git log --date-order --pretty=format:$_git_log_oneline_format"
    alias Gls="git log --date-order --stat"
    alias GlO="git log --date-order --pretty=format:$_git_log_oneline_medium_format"
    alias Glg="git log --date-order --graph"
    alias Gld="git log --date-order --stat --patch"
    alias GlG="git log --date-order --graph --pretty=format:$_git_log_oneline_medium_format"
    alias Glv="git log --date-order --show-signature"
    alias Glf="git log --date-order --stat --patch --follow"
}