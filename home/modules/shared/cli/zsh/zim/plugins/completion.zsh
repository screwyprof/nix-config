#
# Completion enhancements
#

if [[ ${TERM} == dumb ]]; then
  return 1
fi

if (( ${+_comps} )); then
  print -u2 'warning: completion was already initialized before completion module. Will call compinit again. See https://github.com/zimfw/zimfw/wiki/Troubleshooting#completion-is-not-working'
fi

() {
  builtin emulate -L zsh -o EXTENDED_GLOB

  # Simplified dump file check - just check modification time
  local zdumpfile
  zstyle -s ':zim:completion' dumpfile 'zdumpfile' || zdumpfile=${ZDOTDIR:-${HOME}}/.zcompdump
  
  # Use -C to skip expensive checks if dump exists and is from today
  autoload -Uz compinit
  if [[ -f ${zdumpfile} && $(date +%j) == $(date -r ${zdumpfile} +%j) ]]; then
    compinit -C -d ${zdumpfile}
  else
    compinit -d ${zdumpfile} || return 1 
    zcompile ${zdumpfile}
  fi

#
#
# Zsh options
#
local glob_case_sensitivity completion_case_sensitivity
zstyle -s ':zim:glob' case-sensitivity glob_case_sensitivity || glob_case_sensitivity=insensitive
zstyle -s ':zim:completion' case-sensitivity completion_case_sensitivity || completion_case_sensitivity=insensitive

# Move cursor to end of word if a full completion is inserted.
setopt ALWAYS_TO_END

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
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:matches' group yes
#zstyle ':completion:*:options' description yes
#zstyle ':completion:*:options' auto-description '%d'

zstyle ':completion:*:corrections' format "$color02-- %d (errors: %e) --$color07"
#zstyle ':completion:*:descriptions' format "$color03-- %d --$color07"
zstyle ':completion:*:messages' format "$color05-- %d --$color07"
zstyle ':completion:*:warnings' format "$color01-- no matches found --$color07"
#zstyle ':completion:*' format "$color03-- %d --$color07"

zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-grouped true
zstyle ':completion:*' verbose on

if [[ ${completion_case_sensitivity} == sensitive ]]; then
  zstyle ':completion:*' matcher-list '' 'r:|?=**'
else
  zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' '+r:|?=**'
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
#zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*' squeeze-slashes true

# History
# zstyle ':completion:*:history-words' stop yes
# zstyle ':completion:*:history-words' remove-all-dups yes
# zstyle ':completion:*:history-words' list false
# zstyle ':completion:*:history-words' menu yes

# # Populate hostname completion.
# zstyle -e ':completion:*:hosts' hosts 'reply=(
#   ${=${=${=${${(f)"$(cat {/etc/ssh/ssh_,~/.ssh/}known_hosts{,2} 2>/dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
#   ${=${(f)"$(cat /etc/hosts 2>/dev/null; (( ${+commands[ypcat]} )) && ypcat hosts 2>/dev/null)"}%%(\#)*}
#   ${=${${${${(@M)${(f)"$(cat ~/.ssh/config{,.d/*(N)} 2>/dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
# )'

# # Don't complete uninteresting users...
# zstyle ':completion:*:*:*:users' ignored-patterns \
#   '_*' adm amanda apache avahi beaglidx bin cacti canna clamav daemon dbus \
#   distcache dovecot fax ftp games gdm gkrellmd gopher hacluster haldaemon \
#   halt hsqldb ident junkbust ldap lp mail mailman mailnull mldonkey mysql \
#   nagios named netdump news nfsnobody nobody nscd ntp nut nx openvpn \
#   operator pcap postfix postgres privoxy pulse pvm quagga radvd rpc rpcuser \
#   rpm shutdown squid sshd sync uucp vcsa xfs

# Show ignored completion if it's the only match
zstyle ':completion:*' single-ignored show

# remove dups
#zstyle ':completion:*:*:*:*:*' ignore-line yes

# Ignore multiple entries.
zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
zstyle ':completion:*:rm:*' file-patterns '*:all-files'

# Man
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

unset glob_case_sensitivity completion_case_sensitivity
}