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

if ! type "tput" > /dev/null; then
    printf "WARNING: tput command not found on your PATH.\n"
    printf "zsh-you-should-use will fallback to uncoloured messages\n"
else
    NONE="$(tput sgr0)"
    BOLD="$(tput bold)"
    RED="$(tput setaf 1)"
    YELLOW="$(tput setaf 3)"
    PURPLE="$(tput setaf 5)"
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
    local DEFAULT_MESSAGE_FORMAT="${BOLD}${YELLOW}\
Found existing %alias_type for ${PURPLE}\"%command\"${YELLOW}. \
You should use: ${PURPLE}\"%alias\"${NONE}"

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

# Display all matching aliases, sorted by quality (longest first)
# Used in ALL mode to show comprehensive results
function _display_all_matches() {
    local -a sorted_aliases=("$@")
    local key
    local value

    # Show all matches, sorted by quality (longest match first)
    for key in ${sorted_aliases[@]}; do
        value="${aliases[$key]}"
        ysu_message "alias" "$value" "$key"
    done

    # Check hardcore after showing all matches
    if [[ ${#sorted_aliases[@]} -gt 0 ]]; then
        _check_ysu_hardcore "${sorted_aliases[1]}"
    fi
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


function _check_aliases() {
    local typed="$1"
    local expanded="$2"

    local found_aliases=()
    local best_match=""
    local key value

    # 1. Skip sudo commands (use another user's profile)
    if [[ "$typed" = "sudo "* ]]; then
        return
    fi

    # 2. Get aliases and compare user's typed command
    for key value in ${(kv)aliases}; do
        # Skip ignored aliases
        if [[ ${YSU_IGNORED_ALIASES[(r)$key]} == "$key" ]]; then
            continue
        fi

        # 3. Compare what user entered to find matches
        # Match if typed command equals alias expansion OR words overlap
        local -a typed_words=(${=typed})
        local -a value_words=(${=value})
        local match=false

        # Check for exact match
        if [[ "$typed" = "$value" ]]; then
            match=true
        else
            # Check if all words in typed command appear in alias in order
            local typed_idx=1
            for ((i=1; i<=${#value_words[@]}; i++)); do
                if [[ "${value_words[$i]}" = "${typed_words[$typed_idx]}" ]]; then
                    ((typed_idx++))
                    if [[ $typed_idx -gt ${#typed_words[@]} ]]; then
                        match=true
                        break
                    fi
                fi
            done
        fi

        if $match; then
            found_aliases+=("$key")

            # 4. Set best match (first longest match)
            if [[ -z "$best_match" ]]; then
                best_match="$key"
            fi
        fi
    done

    # 4. Show best match first (always)
    if [[ -n "$best_match" ]]; then
        value="${aliases[$best_match]}"
        ysu_message "alias" "$value" "$best_match"
    fi

    # 5. If ALL mode is on, show recommended matches as well
    if [[ "$YSU_MODE" = "ALL" && ${#found_aliases[@]} -gt 1 ]]; then
        # Sort found_aliases by value length (longest first), but skip the best_match we already showed
        local sorted_additional=()
        local alias_values=()

        # Create array of alias:value pairs for sorting, excluding best_match
        for key in ${found_aliases[@]}; do
            if [[ "$key" != "$best_match" ]]; then
                value="${aliases[$key]}"
                alias_values+=("${#value}:${key}")
            fi
        done

        # Sort by length (numeric reverse sort)
        alias_values=(${(On)alias_values})

        # Show additional matches
        for entry in ${alias_values[@]}; do
            key="${entry#*:}"
            value="${aliases[$key]}"
            ysu_message "alias" "$value" "$key"
        done
    fi

    # 6. If hardcore mode is on and best match exists, stop execution
    if [[ -n "$best_match" ]]; then
        _check_ysu_hardcore "$best_match"
    fi

    # Simple 6-step process complete
}

function disable_you_should_use() {
    add-zsh-hook -D preexec _check_aliases
    add-zsh-hook -D preexec _check_global_aliases
    add-zsh-hook -D preexec _check_git_aliases
    add-zsh-hook -D precmd _flush_ysu_buffer
}

function enable_you_should_use() {
    disable_you_should_use   # Delete any possible pre-existing hooks
    add-zsh-hook preexec _check_aliases
    add-zsh-hook preexec _check_global_aliases
    add-zsh-hook preexec _check_git_aliases
    add-zsh-hook precmd _flush_ysu_buffer
}

autoload -Uz add-zsh-hook
enable_you_should_use
