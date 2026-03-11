#
# Completion enhancements
#
# Fork of zimfw/completion with intentional deviations:
# - Nix optimization: date-based compinit instead of zstat fpath fingerprinting
# - fzf-tab compatibility: removed conflicting styles (menu select, format strings, etc.)
# - SSH host completion consolidated here from fzf.nix
# - COMPLETE_IN_WORD disabled intentionally
# - matcher-list uses [:lower:]/[:upper:] syntax (works around Zsh 5.9 bug)
#

if [[ ${TERM} == dumb ]]; then
  return 1
fi

if (( ${+_comps} )); then
  print -u2 'warning: completion was already initialized before completion module. Will call compinit again. See https://github.com/zimfw/zimfw/wiki/Troubleshooting#completion-is-not-working'
fi

() {
  builtin emulate -L zsh -o EXTENDED_GLOB

  # Nix optimization: date-based dump file check instead of zstat fpath fingerprinting.
  # In a Nix-managed system fpath is stable within a generation, so the expensive
  # per-file mtime check is unnecessary. Just rebuild once per day.
  local zdumpfile
  zstyle -s ':zim:completion' dumpfile 'zdumpfile' || zdumpfile=${ZDOTDIR:-${HOME}}/.zcompdump

  autoload -Uz compinit

  if [[ -f ${zdumpfile} && $(date +%j) == $(date -r ${zdumpfile} +%j) ]]; then
    compinit -C -u -d ${zdumpfile}
  else
    compinit -u -d ${zdumpfile} || return 1
    zcompile ${zdumpfile}
  fi
}

# Warn if something tries to re-run compinit (from official — good debugging aid)
functions[compinit]=$'print -u2 \'warning: compinit being called again after completion module at \'${funcfiletrace[1]}
'${functions[compinit]}

#
# Zsh options
#
local glob_case_sensitivity completion_case_sensitivity
zstyle -s ':zim:glob' case-sensitivity glob_case_sensitivity || glob_case_sensitivity=insensitive
zstyle -s ':zim:completion' case-sensitivity completion_case_sensitivity || completion_case_sensitivity=insensitive

# Move cursor to end of word if a full completion is inserted.
setopt ALWAYS_TO_END

# COMPLETE_IN_WORD is intentionally disabled — it interferes with fzf-tab's
# completion behavior and cursor positioning.
# setopt COMPLETE_IN_WORD

if [[ ${glob_case_sensitivity} == sensitive ]]; then
  setopt CASE_GLOB
else
  setopt NO_CASE_GLOB
fi

# Don't beep on ambiguous completions.
setopt NO_LIST_BEEP

#
# Completion module options
#

# Enable caching
zstyle ':completion::complete:*' use-cache on
zstyle ':completion:*' rehash true
zstyle ':completion:*' accept-exact '*(N)'

# Group matches and describe.
# NOTE: 'menu select' deliberately omitted — fzf-tab replaces the menu.
# NOTE: format strings deliberately omitted — fzf-tab renders its own.
# NOTE: 'options description/auto-description' deliberately omitted — conflicts with fzf-tab.
zstyle ':completion:*:matches' group yes
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-grouped true
zstyle ':completion:*' verbose yes

if [[ ${completion_case_sensitivity} == sensitive ]]; then
  zstyle ':completion:*' matcher-list '' 'r:|?=**'
else
  # Use [:lower:]/[:upper:] instead of a-zA-Z — works around Zsh 5.9 bug.
  # See https://www.zsh.org/mla/workers/2022/msg01229.html
  zstyle ':completion:*' matcher-list 'm:{[:lower:]}={[:upper:]}' '+r:|?=**'
fi

# Insert a TAB character instead of performing completion when left buffer is empty.
zstyle ':completion:*' insert-tab false

# Ignore useless commands and functions
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec)|prompt_*)'
# Array completion element sorting.
zstyle ':completion:*:*:-subscript-:*' tag-order 'indexes' 'parameters'

# Directories
if (( ${+LS_COLORS} )); then
  zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
else
  # Use same LS_COLORS definition from utility module, in case it was not set
  zstyle ':completion:*:default' list-colors ${(s.:.):-di=1;34:ln=35:so=32:pi=33:ex=31:bd=1;36:cd=1;33:su=30;41:sg=30;46:tw=30;42:ow=30;43}
fi
zstyle ':completion:*' squeeze-slashes true

# Show ignored completion if it's the only match
zstyle ':completion:*' single-ignored show

# Ignore multiple entries.
zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
zstyle ':completion:*:rm:*' file-patterns '*:all-files'

# Man
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

#
# SSH host completion
#
# Populate hostname completion from ssh config, known_hosts, and /etc/hosts.
zstyle -e ':completion:*:hosts' hosts 'reply=(
  ${=${=${=${${(f)"$(cat {/etc/ssh/ssh_,~/.ssh/}known_hosts{,2} 2>/dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
  ${=${(f)"$(cat /etc/hosts 2>/dev/null; (( ${+commands[ypcat]} )) && ypcat hosts 2>/dev/null)"}%%(\#)*}
  ${=${${${${(@M)${(f)"$(cat ~/.ssh/config{,.d/*(N)} 2>/dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
)'
zstyle ':completion:*:*:ssh:*' tag-order 'hosts:-host:host'
zstyle ':completion:*:*:ssh:*' group-order hosts-host
zstyle ':completion:*:ssh:*' completer _ssh _complete _hosts

unset glob_case_sensitivity completion_case_sensitivity
