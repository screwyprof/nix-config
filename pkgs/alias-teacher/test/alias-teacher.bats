#!/usr/bin/env bats

# Load test helper to get access to TEST_SHELL variable
source test/test_helper.zsh

@test "basic alias suggestion for git status" {
    run $TEST_SHELL '
        # arrange
        source test/test_helper.zsh
        setup_hardcore_all_mode
        setup_common_git_aliases

        # act
        _check_aliases "git status" "git status"
        _flush_ysu_buffer
    '
    # assert
    echo "$output" | grep -q "Best match for.*git status.*GwS"
}

@test "git diff command shows related aliases" {
    run $TEST_SHELL '
        # arrange
        source test/test_helper.zsh
        setup_hardcore_all_mode
        setup_common_git_aliases

        # act
        _check_aliases "git diff" "git diff"
        _flush_ysu_buffer
    '
    # assert - In ALL mode, should show all git diff related aliases
    echo "$output" | grep -q "Best match for.*git.*diff"
    echo "$output" | grep -q "Gwd"
    echo "$output" | grep -q "GwD"
    echo "$output" | grep -q "Gid"
    echo "$output" | grep -q "GiD"
}

@test "git status in ALL mode shows all git status variants" {
    run $TEST_SHELL '
        # arrange
        source test/test_helper.zsh
        setup_hardcore_all_mode
        setup_common_git_aliases

        # act
        _check_aliases "git status" "git status"
        _flush_ysu_buffer
    '

    # assert - ALL mode should show best match + additional recommendations
    echo "$output" | grep -q "Best match for.*git status.*GwS" || { echo "❌ Missing best match for git status"; exit 1; }
    echo "$output" | grep -q "Related aliases for.*git status" || { echo "❌ Missing related aliases section"; exit 1; }
    echo "$output" | grep -q "Gws" || { echo "❌ Missing additional recommendation Gws"; exit 1; }
    echo "$output" | grep -q "Gdi" || { echo "❌ Missing additional recommendation Gdi"; exit 1; }
}

@test "git diff --cached shows only cached-related aliases" {
    run $TEST_SHELL '
        # arrange
        source test/test_helper.zsh
        setup_hardcore_all_mode
        setup_common_git_aliases

        # act
        _check_aliases "git diff --cached" "git diff --cached"
        _flush_ysu_buffer
    '

    # assert
    echo "$output" | grep -qv "Gwd" || { echo "❌ Gwd incorrectly included"; exit 1; }
    echo "$output" | grep -qv "GwD" || { echo "❌ GwD incorrectly included"; exit 1; }
    echo "$output" | grep -q "Gid" || { echo "❌ Missing Gid"; exit 1; }
    echo "$output" | grep -q "GiD" || { echo "❌ Missing GiD"; exit 1; }
}

@test "best match should prioritize exact matches over longest partial matches" {
    run $TEST_SHELL '
        # arrange
        source test/test_helper.zsh
        setup_hardcore_all_mode
        setup_common_git_aliases

        # Set up aliases where there is no exact match for "git log"
        # but there is a general "G" alias for "git"

        # act
        _check_aliases "git log" "git log"
        _flush_ysu_buffer
    '
    # assert - The best match should be "G" for "git" since there is no exact "git log" alias
    echo "$output" | grep -q "Best match for.*git log.*G" || { echo "❌ Should recommend G as best match for git log"; exit 1; }
    echo "$output" | grep -q "GlO" || { echo "❌ Should show GlO as related alias"; exit 1; }
    echo "$output" | grep -qv "Best match for.*git log.*GlO" || { echo "❌ GlO should not be best match since it adds flags"; exit 1; }
}