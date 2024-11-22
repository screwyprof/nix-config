() {
  local -r target=${ZIM_HOME:-${ZDOTDIR:-$HOME/.zim}}/modules/thefuck/init.zsh
  shift
  (( ${+commands[${1}]} )) || return 1
  if [[ ! ( -s ${target} && ${target} -nt ${commands[${1}]} ) ]]; then
    mkdir -p ${target:h}
    # Generate the thefuck function with custom keybinding
    cat >! ${target} << 'EOL'
    eval "$(thefuck --alias)"
    
    # Custom keybinding for fuck
    fuck-command-line() {
      BUFFER="fuck"
      zle accept-line
    }
    zle -N fuck-command-line
    bindkey '\ef' fuck-command-line
EOL
    zcompile -UR ${target}
  fi
  source ${target}
} ${0:h}/init.zsh thefuck --alias || return 1