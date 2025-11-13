#!/bin/zsh
#
# alias-teacher - An enhanced ZSH plugin for learning and using shell aliases
# 
# Based on zsh-you-should-use by Michael Aquilina
# https://github.com/MichaelAquilina/zsh-you-should-use
#
# Enhanced with:
# - Better alias matching (finds most specific match)
# - Alias discovery (shows related aliases)
# - Improved learning support
#
# Licensed under GPL-3.0

export YSU_VERSION='2.0.0'  # Forked from YSU 1.10.1
export ALIAS_TEACHER_VERSION='2.0.0'

# =============================================================================
# CONFIGURATION VARIABLES
# =============================================================================
# User-configurable settings - modify these in your .zshrc as needed

# YSU_MAX_LINE_LENGTH: Maximum line length before truncation (default: 120)
# Modern recommendation: 120 chars for good readability on most displays
# Usage: export YSU_MAX_LINE_LENGTH=100
export YSU_MAX_LINE_LENGTH="${YSU_MAX_LINE_LENGTH:-120}"

# YSU_MODE: Display mode for alias suggestions
# Options: "ALL" (show all related), "BESTMATCH" (show best match only)
# Usage: export YSU_MODE="ALL"
export YSU_MODE="${YSU_MODE:-BESTMATCH}"

# Backward compatibility: YSU_MODE=ALL implies YSU_SHOW_RECOMMENDED=1
if [[ "$YSU_MODE" == "ALL" ]]; then
    YSU_SHOW_RECOMMENDED=1
fi

# YSU_HARDCORE: Enable hardcore mode to stop execution when alias found
# Options: 1 (enabled), 0 (disabled), or set for specific aliases only
# Usage: export YSU_HARDCORE=1
# Usage: export YSU_HARDCORE_ALIASES=(G Gs)

# YSU_MESSAGE_POSITION: When to show messages
# Options: "before" (before command runs), "after" (after command)
# Usage: export YSU_MESSAGE_POSITION="after"
export YSU_MESSAGE_POSITION="${YSU_MESSAGE_POSITION:-before}"

# YSU_IGNORED_ALIASES: Array of aliases to ignore
# Usage: export YSU_IGNORED_ALIASES=(ls ll)
typeset -ga YSU_IGNORED_ALIASES

# YSU_MESSAGE_FORMAT: Custom message format (advanced)
# Variables: %alias_type, %command, %alias
# Usage: export YSU_MESSAGE_FORMAT="Found alias %alias for %command"

if ! type "tput" > /dev/null; then
    printf "WARNING: tput command not found on your PATH.\n"
    printf "zsh-you-should-use will fallback to uncoloured messages\n"
else
    NONE="$(tput sgr0)"
    BOLD="$(tput bold)"

    # Define consistent color scheme
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
    PURPLE="$(tput setaf 5)"
    CYAN="$(tput setaf 6)"
    WHITE="$(tput setaf 7)"
fi

function check_alias_usage() {
    # Optional parameter that limits how far back history is checked
    # I've chosen a large default value instead of bypassing tail because it's simpler
    local limit="${1:-${HISTSIZE:-9000000000000000}}"
    local key

    declare -A usage
    for key in "${(@k)aliases}"; do
        usage[$key]=0
    done

    # TODO:
    # Handle and (&&) + (&)
    # others? watch, time etc...

    local -a histfile_lines
    histfile_lines=("${(@f)$(<$HISTFILE)}")
    histfile_lines=("${histfile_lines[@]#*;}")

    local current=0
    local total=${#histfile_lines}
    if [[ $total -gt $limit ]]; then
        total=$limit
    fi

    local entry
    for line in ${histfile_lines[@]} ; do
        for entry in ${(@s/|/)line}; do
            # Remove leading whitespace
            entry=${entry##*[[:space:]]}

            # We only care about the first word because that's all aliases work with
            # (this does not count global and git aliases)
            local word=${entry[(w)1]}
            if [[ -n ${usage[$word]} ]]; then
                (( usage[$word]++ ))
            fi
        done

        # print current progress
        (( current++ ))
        printf "Analysing: [$current/$total]\r"
    done
    # Clear all previous line output
    printf "\r\033[K"

    # Print ordered usage
    for key in ${(k)usage}; do
        echo "${usage[$key]}: ${(q+)key}=${(q+)aliases[$key]}"
    done | sort -rn -k1
}

# Writing to a buffer rather than directly to stdout/stderr allows us to decide
# if we want to write the reminder message before or after a command has been executed
function _write_ysu_buffer() {
    _YSU_BUFFER+="$@"

    # Maintain historical behaviour by default
    local position="${YSU_MESSAGE_POSITION:-before}"
    if [[ "$position" = "before" ]]; then
        _flush_ysu_buffer
    elif [[ "$position" != "after" ]]; then
        (>&2 printf "${RED}${BOLD}Unknown value for YSU_MESSAGE_POSITION '$position'. ")
        (>&2 printf "Expected value 'before' or 'after'${NONE}\n")
        _flush_ysu_buffer
    fi
}

function _flush_ysu_buffer() {
    # It's important to pass $_YSU_BUFFER to printfs first argument
    # because otherwise all escape codes will not printed correctly
    (>&2 printf "$_YSU_BUFFER")
    _YSU_BUFFER=""
}

function ysu_message() {
    local DEFAULT_MESSAGE_FORMAT="${BOLD}${CYAN}\
Found existing %alias_type for ${BLUE}\"%command\"${CYAN}. \
You should use: ${YELLOW}\"%alias\"${NONE}"

    local alias_type_arg="${1}"
    local command_arg="${2}"
    local alias_arg="${3}"

    # Escape arguments which will be interpreted by printf incorrectly
    # unfortunately there does not seem to be a nice way to put this into
    # a function because returning the values requires to be done by printf/echo!!
    command_arg="${command_arg//\%/%%}"
    command_arg="${command_arg//\\/\\\\}"

    local MESSAGE="${YSU_MESSAGE_FORMAT:-"$DEFAULT_MESSAGE_FORMAT"}"
    MESSAGE="${MESSAGE//\%alias_type/$alias_type_arg}"
    MESSAGE="${MESSAGE//\%command/$command_arg}"
    MESSAGE="${MESSAGE//\%alias/$alias_arg}"

    _write_ysu_buffer "$MESSAGE\n"
}


# Prevent command from running if hardcore mode enabled
function _check_ysu_hardcore() {
    local alias_name="$1"

    local hardcore_lookup="${YSU_HARDCORE_ALIASES[(r)$alias_name]}"
    if (( ${+YSU_HARDCORE} )) || [[ -n "$hardcore_lookup" && "$hardcore_lookup" == "$alias_name" ]]; then
        _write_ysu_buffer "${BOLD}${RED}You Should Use hardcore mode enabled. Use your aliases!${NONE}\n"
        kill -s INT $$
    fi
}

# Helper function to check if typed command matches alias value
function _command_matches() {
    local typed="$1"
    local value="$2"

    # Exact match
    [[ "$typed" = "$value" ]] && return 0

    # Typed command is prefix of alias (e.g., "git status" matches "git status --short")
    [[ "$typed" = "$value "* ]] && return 0

    # Check semantic match - same base command and subcommand
    local -a typed_words=(${=typed})
    local -a value_words=(${=value})

    # Need at least base command and subcommand for semantic matching
    [[ ${#typed_words[@]} -lt 2 || ${#value_words[@]} -lt 2 ]] && return 1

    # Base command and main subcommand must match exactly
    [[ "${typed_words[1]}" != "${value_words[1]}" ]] && return 1
    [[ "${typed_words[2]}" != "${value_words[2]}" ]] && return 1

    # Check if all typed words appear in alias value in order
    local typed_idx=1
    for ((i=1; i<=${#value_words[@]}; i++)); do
        if [[ "${value_words[$i]}" = "${typed_words[$typed_idx]}" ]]; then
            ((typed_idx++))
            [[ $typed_idx -gt ${#typed_words[@]} ]] && return 0
        fi
    done

    return 1
}

# Helper function to format commands for display (copy-paste friendly)
function _quote_command() {
    local command="$1"

    # Don't quote at all - display as-is for easy copy-paste
    # The complex commands will be displayed without extra quoting
    echo "$command"
}

# Helper function to smartly truncate long commands at word boundaries
function _truncate_command() {
    local command="$1"
    # Use user-configurable length (set at top of file)
    local max_length="${2:-$YSU_MAX_LINE_LENGTH}"

    # If command is short enough, return as-is
    if [[ ${#command} -le $max_length ]]; then
        echo "$command"
        return
    fi

    # Truncate at word boundary, ending with "..."
    local truncated="${command:0:$((max_length - 3))}"

    # Find the last space to avoid breaking words
    local last_space="${truncated##* }"
    if [[ "$last_space" != "$truncated" ]]; then
        # Remove the partial word after the last space
        truncated="${truncated% *}"
    fi

    echo "${truncated}..."
}


# Helper function to check if two commands are semantically related
function _commands_are_related() {
    local typed="$1"
    local alias_value="$2"

    # Parse typed command structure
    local -a typed_parts=(${(s/ /)typed})
    local typed_base="$typed_parts[1]"
    local typed_main_cmd="$typed_parts[2]"

    # Parse alias command structure
    local -a alias_parts=(${(s/ /)alias_value})
    local alias_base="$alias_parts[1]"
    local alias_main_cmd="$alias_parts[2]"

    # Commands are related if base command and main subcommand match exactly
    [[ "$alias_base" = "$typed_base" && "$alias_main_cmd" = "$typed_main_cmd" ]]
}


function _check_git_aliases() {
    local typed="$1"
    local expanded="$2"

    # sudo will use another user's profile and so aliases would not apply
    if [[ "$typed" = "sudo "* ]]; then
        return
    fi

    if [[ "$typed" = "git "* ]]; then
        local found=false
        git config --get-regexp "^alias\..+$" | sort | while read key value; do
            key="${key#alias.}"

            # if for some reason, read does not split correctly, we
            # detect that and manually split the key and value
            if [[ -z "$value" ]]; then
                value="${key#* }"
                key="${key%% *}"
            fi

            if [[ "$expanded" = "git $value" || "$expanded" = "git $value "* ]]; then
                ysu_message "git alias" "$value" "git $key"
                found=true
            fi
        done

        if $found; then
            _check_ysu_hardcore
        fi
    fi
}


function _check_global_aliases() {
    local typed="$1"
    local expanded="$2"

    local found=false
    local tokens
    local key
    local value
    local entry

    # sudo will use another user's profile and so aliases would not apply
    if [[ "$typed" = "sudo "* ]]; then
        return
    fi

    alias -g | sort | while IFS="=" read -r key value; do
        key="${key## }"
        key="${key%% }"
        value="${(Q)value}"

        # Skip ignored global aliases
        if [[ ${YSU_IGNORED_GLOBAL_ALIASES[(r)$key]} == "$key" ]]; then
            continue
        fi

        if [[ "$typed" = *" $value "* || \
              "$typed" = *" $value" || \
              "$typed" = "$value "* || \
              "$typed" = "$value" ]]; then
            ysu_message "global alias" "$value" "$key"
            found=true
        fi
    done

    if $found; then
        _check_ysu_hardcore
    fi
}

# Helper function to check if a boolean variable is true
_is_true() {
    local var="$1"
    [[ -z "$var" ]] && return 1
    var="${var:l}"
    case "$var" in
        1|true|yes|on|enabled) return 0 ;;
        0|false|no|off|disabled|"") return 1 ;;
        *) return 1 ;;
    esac
}

# Handle command execution logic
function _handle_command_execution() {
    local cmd="$1"
    [[ -z "$cmd" ]] && return 0

    _find_best_alias "$cmd" "$cmd"
    local best_match_alias="${_ALIAS_RESULT[best_match]}"
    [[ -z "$best_match_alias" ]] && return 0

    _check_aliases "$cmd" "$cmd"

    if _is_true "$YSU_HARDCORE" || [[ -n "${YSU_HARDCORE_ALIASES[(r)$best_match_alias]}" ]]; then
        _write_ysu_buffer "${BOLD}${RED}Hardcore mode: Use your alias instead!${NONE}\n"
        _flush_ysu_buffer
        return 1
    fi

    return 0
}

# Create widget wrapper
alias_teacher_accept_line_wrapper() {
    _handle_command_execution "$BUFFER"
    [[ $? -eq 0 ]] && zle .accept-line || { BUFFER=""; zle redisplay; }
}

# Find the best alias match for a given command
function _find_best_alias() {
    local typed="$1"
    local expanded="$2"
    typeset -gA _ALIAS_RESULT=()
    local -a exact_matches=()
    local -a prefix_matches=()   # typed is prefix of alias (safer, shorter)
    local -a other_matches=()    # other semantic matches

    # Check regular aliases
    for key value in ${(kv)aliases}; do
        [[ ${YSU_IGNORED_ALIASES[(r)$key]} == "$key" ]] && continue

        # Exact match
        if [[ "$typed" = "$value" ]]; then
            exact_matches+=("$key")
        # Prefix match (typed is prefix of alias) - safest fallback
        elif [[ "$typed" = "$value "* ]]; then
            prefix_matches+=("$key")
        # Semantic matches
        elif _command_matches "$typed" "$value"; then
            other_matches+=("$key")
        fi
    done

    # Check global aliases
    local global_aliases_output
    global_aliases_output=$(alias -g)
    while IFS="=" read -r key value; do
        [[ -z "$key" ]] && continue
        key="${key## *}"; key="${key%% *}"; value="${(Q)value}"
        [[ ${YSU_IGNORED_ALIASES[(r)$key]} == "$key" ]] && continue

        # Exact match
        if [[ "$typed" = "$value" ]]; then
            exact_matches+=("$key")
        # Global aliases are always "other" matches (can be risky)
        elif [[ "$typed" = *"$value"* ]]; then
            other_matches+=("$key")
        fi
    done <<< "$global_aliases_output"

    # Check git aliases
    if [[ "$typed" = "git "* ]]; then
        local git_aliases_output
        git_aliases_output=$(git config --get-regexp "^alias\..+$" 2>/dev/null || true)
        while read key value; do
            [[ -z "$key" ]] && continue
            key="${key#alias.}"
            [[ -z "$value" ]] && { value="${key#* }"; key="${key%% *}"; }

            # Create git command: "git " + value
            local git_command="git $value"

            # Exact match
            if [[ "$typed" = "$git_command" ]]; then
                exact_matches+=("$key")
            # Prefix match (typed is prefix of git alias)
            elif [[ "$typed" = "$git_command "* ]]; then
                prefix_matches+=("$key")
            # Semantic git matches
            else
                other_matches+=("$key")
            fi
        done <<< "$git_aliases_output"
    fi

    # Sort matches by length (shortest first) for safety
    local -a sorted_prefix_matches=(${(o)prefix_matches})
    local -a sorted_other_matches=(${(o)other_matches})

    # Combine matches with priority: exact > prefix (shortest) > other (shortest)
    local -a all_matches=()
    [[ ${#exact_matches[@]} -gt 0 ]] && all_matches+=($exact_matches)
    [[ ${#sorted_prefix_matches[@]} -gt 0 ]] && all_matches+=($sorted_prefix_matches)
    [[ ${#sorted_other_matches[@]} -gt 0 ]] && all_matches+=($sorted_other_matches)

    _ALIAS_RESULT[best_match]="${all_matches[1]}"
    _ALIAS_RESULT[found_aliases]="${all_matches[@]}"
}

function _check_aliases() {
    local typed="$1"
    expanded="$2"

    [[ "$typed" = "sudo "* ]] && return

    _find_best_alias "$typed" "$expanded"
    local best_match="${_ALIAS_RESULT[best_match]}"
    [[ -z "$best_match" ]] && return

    local -a found_aliases=(${(s/ /)_ALIAS_RESULT[found_aliases]})

    # Determine if we have an exact match
    local best_match_value="${aliases[$best_match]}"
    local is_exact_match=false

    if [[ "$best_match_value" = "$typed" ]]; then
        is_exact_match=true
    fi

    # Show match section with appropriate header
    if [[ "$is_exact_match" = true ]]; then
        _write_ysu_buffer "\n${BOLD}${GREEN}Alias found for ${BLUE}\"$typed\"${GREEN}:${NONE}\n"
    else
        _write_ysu_buffer "\n${BOLD}${GREEN}Best match for ${BLUE}\"$typed\"${GREEN}:${NONE}\n"
    fi

    printf -v formatted_line "  ${YELLOW}%s${NONE} ${BLUE}→${NONE} %s\n" "$best_match" "$(_truncate_command "$(_quote_command "$best_match_value")")"
    _write_ysu_buffer "$formatted_line"

    # Show related aliases if enabled
    _is_true "$YSU_SHOW_RECOMMENDED" || return
    [[ ${#found_aliases[@]} -gt 1 ]] || return

    local -a related_aliases=()
    for key in ${found_aliases[@]}; do
        [[ "$key" == "$best_match" ]] && continue
        local alias_value="${aliases[$key]}"
        if _commands_are_related "$typed" "$alias_value"; then
            related_aliases+=("$key")
        fi
    done

    [[ ${#related_aliases[@]} -eq 0 ]] && return

    _write_ysu_buffer "${BLUE}Related aliases:${NONE}\n"
    related_aliases=(${(i)related_aliases})

    local max_alias_length=0
    for key in ${related_aliases[@]}; do
        [[ ${#key} -gt $max_alias_length ]] && max_alias_length=${#key}
    done

    for key in ${related_aliases[@]}; do
        local alias_value="${aliases[$key]}"
        local quoted_value="$(_quote_command "$alias_value")"
        local truncated_value="$(_truncate_command "$quoted_value")"
        truncated_value="${truncated_value//\%/%%}"
        printf -v formatted_line "  ${YELLOW}%-${max_alias_length}s${NONE} ${BLUE}→${NONE} %s\n" "$key" "$truncated_value"
        _write_ysu_buffer "$formatted_line"
    done
}

# Initialize widget system
autoload -Uz add-zsh-hook
zle -N alias_teacher_accept_line_wrapper
bindkey '^M' alias_teacher_accept_line_wrapper
