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
    echo "$output" | grep -q "Alias found for.*git status"
    echo "$output" | grep -q "GwS.*git status"
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
    echo "$output" | grep -q "Related aliases"
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
    echo "$output" | grep -q "Alias found for.*git status" || { echo "❌ Missing exact match for git status"; exit 1; }
    echo "$output" | grep -q "GwS.*git status" || { echo "❌ Missing best match GwS"; exit 1; }
    echo "$output" | grep -q "Related aliases" || { echo "❌ Missing related aliases section"; exit 1; }
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
    echo "$output" | grep -q "Best match for.*git log" || { echo "❌ Should show best match for git log"; exit 1; }
    echo "$output" | grep -q "G.*git" || { echo "❌ Should recommend G as best match for git log"; exit 1; }
    echo "$output" | grep -q "GlO" || { echo "❌ Should show GlO as related alias"; exit 1; }
}

@test "git diff should show Best match with G fallback when no exact match exists" {
    run $TEST_SHELL '
        # arrange
        source test/test_helper.zsh
        setup_hardcore_all_mode
        setup_common_git_aliases

        # act
        _check_aliases "git diff" "git diff"
        _flush_ysu_buffer
    '
    # assert - Should show "Best match" not "Exact match" when no exact match exists
    echo "$output" | grep -q "Best match for.*git diff" || { echo "❌ Should show Best match for git diff (no exact match exists)"; exit 1; }
    # Should NOT show "Exact match" when no exact match exists
    echo "$output" | grep -q "Exact match for.*git diff" && { echo "❌ Should NOT show Exact match for git diff (no exact match exists)"; exit 1; }
    # Should NOT show "Alias found for" when no exact match exists
    echo "$output" | grep -q "Alias found for.*git diff" && { echo "❌ Should NOT show Alias found for git diff (no exact match exists)"; exit 1; }
    # G should be the best match since no alias exactly matches "git diff"
    echo "$output" | grep -A1 "Best match for.*git diff" | grep -q "G.*git" || { echo "❌ G should be best match since no exact git diff alias exists"; exit 1; }
    # Should show Related aliases section after best match
    echo "$output" | grep -q "Related aliases" || { echo "❌ Should show Related aliases section"; exit 1; }
}

@test "git status should show Alias found for when exact match exists" {
    run $TEST_SHELL '
        # arrange
        source test/test_helper.zsh
        setup_hardcore_all_mode
        setup_common_git_aliases

        # act
        _check_aliases "git status" "git status"
        _flush_ysu_buffer
    '
    # assert - Should show "Alias found for" when exact match exists (GwS="git status")
    echo "$output" | grep -q "Alias found for.*git status" || { echo "❌ Should show Alias found for git status (exact match exists)"; exit 1; }
    # Should NOT show "Best match" when exact match exists
    echo "$output" | grep -q "Best match for.*git status" && { echo "❌ Should NOT show Best match for git status (exact match exists)"; exit 1; }
    # Should NOT show "Exact match" - use "Alias found for" instead
    echo "$output" | grep -q "Exact match for.*git status" && { echo "❌ Should NOT show Exact match for git status (use Alias found for)"; exit 1; }
    # GwS should be shown as the exact match
    echo "$output" | grep -A1 "Alias found for.*git status" | grep -q "GwS.*git status" || { echo "❌ GwS should be shown as alias for git status"; exit 1; }
}

@test "git diff --cached should show Best match when no exact match exists" {
    run $TEST_SHELL '
        # arrange
        source test/test_helper.zsh
        setup_hardcore_all_mode
        setup_common_git_aliases

        # act
        _check_aliases "git diff --cached" "git diff --cached"
        _flush_ysu_buffer
    '
    # assert - Should show "Best match" not "Exact match" when no exact match exists
    echo "$output" | grep -q "Best match for.*git diff --cached" || { echo "❌ Should show Best match for git diff --cached (no exact match exists)"; exit 1; }
    # Should NOT show "Exact match" when no exact match exists
    echo "$output" | grep -q "Exact match for.*git diff --cached" && { echo "❌ Should NOT show Exact match for git diff --cached (no exact match exists)"; exit 1; }
    # G should be the best match since no alias exactly matches "git diff --cached"
    echo "$output" | grep -A1 "Best match for.*git diff --cached" | grep -q "G.*git" || { echo "❌ G should be best match since no exact git diff --cached alias exists"; exit 1; }
}