() {
   local -r target=${ZIM_HOME:-${ZDOTDIR:-$HOME/.zim}}/modules/zoxide/init.zsh
  shift
  (( ${+commands[${1}]} )) || return 1
  if [[ ! ( -s ${target} && ${target} -nt ${commands[${1}]} ) ]]; then
    mkdir -p ${target:h}
    "${@}" >! ${target} || return 1
    zcompile -UR ${target}
  fi
  source ${target}
} ${0:h}/init.zsh zoxide init zsh --cmd cd || return 1