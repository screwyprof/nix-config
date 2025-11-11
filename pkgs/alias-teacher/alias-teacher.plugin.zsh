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

    local found_aliases
    found_aliases=()
    local best_match=""
    local best_match_value=""
    local key
    local value

    # sudo will use another user's profile and so aliases would not apply
    if [[ "$typed" = "sudo "* ]]; then
        return
    fi

    # Build array of aliases sorted by value length for better matching
    local -a sorted_by_length=()
    for key in "${(@k)aliases}"; do
        value="${aliases[$key]}"
        
        # Skip ignored aliases
        if [[ ${YSU_IGNORED_ALIASES[(r)$key]} == "$key" ]]; then
            continue
        fi
        
        # Skip aliases that are longer than their expansions
        if [[ "${#value}" -gt "${#key}" ]]; then
            sorted_by_length+=("${#value}:${key}:${value}")
        fi
    done
    
    # Sort by length (numeric reverse)
    sorted_by_length=(${(On)sorted_by_length})
    
    # Find alias matches using the sorted list
    for entry in ${sorted_by_length[@]}; do
        local len="${entry%%:*}"
        local rest="${entry#*:}"
        key="${rest%%:*}"
        value="${rest#*:}"

        if [[ "$typed" = "$value" || "$typed" = "$value "* ]]; then
            found_aliases+="$key"

            # First match in sorted list is the best match (longest value)
            if [[ -z "$best_match" ]]; then
                best_match="$key"
                best_match_value="$value"
            fi
        fi
    done

    # Print result matches based on current mode
    if [[ "$YSU_MODE" = "ALL" ]]; then
        # Sort found_aliases by value length (longest first)
        local sorted_aliases=()
        local alias_values=()
        
        # Create array of alias:value pairs for sorting
        for key in ${found_aliases[@]}; do
            value="${aliases[$key]}"
            alias_values+=("${#value}:${key}")
        done
        
        # Sort by length (numeric reverse sort)
        alias_values=(${(On)alias_values})
        
        # Extract sorted keys
        for entry in ${alias_values[@]}; do
            key="${entry#*:}"
            sorted_aliases+=("$key")
        done
        
        # In hardcore mode with ALL, only show the best match
        if (( ${+YSU_HARDCORE} )); then
            if [[ -n "$best_match" ]]; then
                value="${aliases[$best_match]}"
                ysu_message "alias" "$value" "$best_match"

                
                # Show related aliases even in hardcore mode for discovery
                # Use the same logic as BESTMATCH mode - show related if typed starts with best_match_value
                if [[ -n "$best_match" && "$typed" =~ "^$best_match_value " ]]; then
                    local -a related_aliases=()
                    local -a typed_parts=(${(s/ /)typed})
                    local typed_base="$typed_parts[1]"
                    local typed_main_cmd="$typed_parts[2]"

                    if [[ ${#typed_parts[@]} -gt 2 ]]; then
                        local typed_flags="${typed_parts[3,-1]}"
                    else
                        local typed_flags=""
                    fi

                    for key in "${(@k)aliases}"; do
                        local alias_value="${aliases[$key]}"

                        # Skip the best match we already showed
                        if [[ "$key" == "$best_match" ]]; then
                            continue
                        fi

                        # Parse alias structure the same way
                        local -a alias_parts=(${(s/ /)alias_value})
                        local alias_base="$alias_parts[1]"
                        local alias_main_cmd="$alias_parts[2]"

                        # Skip if not same base command and subcommand
                        if [[ "$alias_base" != "$typed_base" || "$alias_main_cmd" != "$typed_main_cmd" ]]; then
                            continue
                        fi

                        
                        if [[ ${#alias_parts[@]} -gt 2 ]]; then
                            local alias_flags="${alias_parts[3,-1]}"
                        else
                            local alias_flags=""
                        fi

                        # Show if:
                        # 1. Alias has no extra flags (base version) - only if typed also has no flags
                        # 2. Typed command contains all alias flags (for more specific aliases)
                        # 3. Alias contains all typed command flags (for less specific aliases)

                        local should_show=false

                        if [[ -z "$typed_flags" && -z "$alias_flags" ]]; then
                            # Both are base commands
                            should_show=true
                        elif [[ -n "$typed_flags" && -n "$alias_flags" ]]; then
                            # Both have flags - check if they're related
                            # Check if typed flags contain alias flags OR alias flags contain typed flags
                            local typed_contains_alias=true
                            local alias_contains_typed=true

                            # Check if typed contains all alias flags
                            for flag in ${=alias_flags}; do
                                if [[ ! " ${=typed_flags} " =~ " $flag " ]]; then
                                    typed_contains_alias=false
                                    break
                                fi
                            done

                            # Check if alias contains all typed flags
                            for flag in ${=typed_flags}; do
                                if [[ ! " ${=alias_flags} " =~ " $flag " ]]; then
                                    alias_contains_typed=false
                                    break
                                fi
                            done

                            if $typed_contains_alias || $alias_contains_typed; then
                                should_show=true
                            fi
                        else
                            # One has flags, one doesn't - be more selective
                            # If user typed base command (no flags), show all variations for discovery
                            # If user typed specific flags, only show closely related aliases
                            if [[ -z "$typed_flags" ]]; then
                                # User typed base command, show all flag variations for discovery
                                should_show=true
                            else
                                # User typed specific flags, only show if aliases share common purpose
                                should_show=false

                                # Check for shared functionality between typed and alias flags
                                if [[ "$typed_flags" =~ "cached" ]] && [[ "$alias_flags" =~ "cached" ]]; then
                                    should_show=true
                                elif [[ "$typed_flags" =~ "cached" ]] && [[ "$alias_flags" =~ "staged" ]]; then
                                    should_show=true
                                elif [[ "$typed_flags" =~ "staged" ]] && [[ "$alias_flags" =~ (cached|staged) ]]; then
                                    should_show=true
                                elif [[ "$typed_flags" =~ "word-diff" ]] && [[ "$alias_flags" =~ "word-diff" ]]; then
                                    should_show=true
                                fi
                            fi
                        fi

                        
                        if $should_show; then
                            related_aliases+=("$key")
                        fi
                    done

                    if [[ ${#related_aliases[@]} -gt 0 ]]; then
                        _write_ysu_buffer "${PURPLE}Related aliases for \"$typed\":${NONE}\n"
                        local -a sorted_related=()
                        for key in ${related_aliases[@]}; do
                            local alias_value="${aliases[$key]}"
                            sorted_related+=("${#alias_value}:${key}:${alias_value}")
                        done
                        sorted_related=(${(n)sorted_related})
                        
                        for entry in ${sorted_related[@]}; do
                            local rest="${entry#*:}"
                            local key="${rest%%:*}"
                            local value="${rest#*:}"
                            _write_ysu_buffer "  ${YELLOW}${key}${NONE}: ${value}\n"
                        done
                    fi
                fi
                
                _check_ysu_hardcore "$best_match"
            fi
        else
            # Show all matches, sorted by quality (longest match first)
            for key in ${sorted_aliases[@]}; do
                value="${aliases[$key]}"
                ysu_message "alias" "$value" "$key"
            done

            # Check hardcore after showing all matches
            if [[ ${#sorted_aliases[@]} -gt 0 ]]; then
                _check_ysu_hardcore "${sorted_aliases[1]}"
            fi
        fi

    elif [[ (-z "$YSU_MODE" || "$YSU_MODE" = "BESTMATCH") && -n "$best_match" ]]; then
        # make sure that the best matched alias has not already
        # been typed by the user
        value="${aliases[$best_match]}"
        if [[ "$typed" = "$best_match" || "$typed" = "$best_match "* ]]; then
            return
        fi
        ysu_message "alias" "$value" "$best_match"
        
        # Check if this is a generic match that could have more specific alternatives
        # For example, if best_match is "G" for "git diff", show related git diff aliases
        # Show related aliases if typed command starts with best match value (e.g., "git diff" starts with "git")
        if [[ -n "$best_match" && "$typed" =~ "^$best_match_value " ]]; then
              # Find related aliases that start with the typed command
            local -a related_aliases=()
            for key in "${(@k)aliases}"; do
                local alias_value="${aliases[$key]}"
                # Skip the best match we already showed
                if [[ "$key" == "$best_match" ]]; then
                    continue
                fi
                # Check if this alias starts with the typed command + space OR
                # if the typed command contains this alias as a prefix with additional flags
                # OR if this alias starts with the base command of typed
                # Parse command structure for better matching

                # Parse command structure for better matching
                local -a typed_parts=(${(s/ /)typed})
                local typed_base="$typed_parts[1]"           # git
                local typed_main_cmd="$typed_parts[2]"       # diff (or empty if just 'git')

                if [[ ${#typed_parts[@]} -gt 2 ]]; then
                    local typed_flags="${typed_parts[3,-1]}"  # everything after 3rd element
                else
                    local typed_flags=""
                fi

                # Parse alias structure the same way
                local -a alias_parts=(${(s/ /)alias_value})
                local alias_base="$alias_parts[1]"
                local alias_main_cmd="$alias_parts[2]"

                # Skip if not same base command and subcommand
                if [[ "$alias_base" != "$typed_base" || "$alias_main_cmd" != "$typed_main_cmd" ]]; then
                    continue
                fi

                if [[ ${#alias_parts[@]} -gt 2 ]]; then
                    local alias_flags="${alias_parts[3,-1]}"
                else
                    local alias_flags=""
                fi

                # Show if:
                # 1. Alias has no extra flags (base version) - only if typed also has no flags
                # 2. Typed command contains all alias flags (for more specific aliases)
                # 3. Alias contains all typed command flags (for less specific aliases)

                local should_show=false

                if [[ -z "$typed_flags" && -z "$alias_flags" ]]; then
                    # Both are base commands
                    should_show=true
                elif [[ -n "$typed_flags" && -n "$alias_flags" ]]; then
                    # Both have flags - check if they're related
                    # Check if typed flags contain alias flags OR alias flags contain typed flags
                    local typed_contains_alias=true
                    local alias_contains_typed=true

                    # Check if typed contains all alias flags
                    for flag in ${=alias_flags}; do
                        if [[ ! " ${=typed_flags} " =~ " $flag " ]]; then
                            typed_contains_alias=false
                            break
                        fi
                    done

                    # Check if alias contains all typed flags
                    for flag in ${=typed_flags}; do
                        if [[ ! " ${=alias_flags} " =~ " $flag " ]]; then
                            alias_contains_typed=false
                            break
                        fi
                    done

                    if $typed_contains_alias || $alias_contains_typed; then
                        should_show=true
                    fi
                else
                    # One has flags, one doesn't - show for discovery
                    if [[ -z "$typed_flags" ]] || [[ -z "$alias_flags" ]]; then
                        should_show=true
                    fi
                fi

                if $should_show; then
                    related_aliases+=("$key")
                fi
            done
            
            # If we found related aliases, show them
            if [[ ${#related_aliases[@]} -gt 0 ]]; then
                _write_ysu_buffer "${PURPLE}Related aliases for \"$typed\":${NONE}\n"
                
                # Sort related aliases by their value length
                local -a sorted_related=()
                for key in ${related_aliases[@]}; do
                    local alias_value="${aliases[$key]}"
                    sorted_related+=("${#alias_value}:${key}:${alias_value}")
                done
                sorted_related=(${(n)sorted_related})
                
                # Display sorted related aliases
                for entry in ${sorted_related[@]}; do
                    local rest="${entry#*:}"
                    local key="${rest%%:*}"
                    local value="${rest#*:}"
                    _write_ysu_buffer "  ${YELLOW}${key}${NONE}: ${value}\n"
                done
            fi
        fi
        
        _check_ysu_hardcore "$best_match"
    fi
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
