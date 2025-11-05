() {
  local -r target=${ZIM_HOME:-${ZDOTDIR:-$HOME/.zim}}/modules/enhanced-paste/init.zsh
  
  if [[ ! -s ${target} ]]; then
    mkdir -p ${target:h}
    cat > ${target} << 'EOF'
# Disable the default paste highlighting
# https://github.com/zsh-users/zsh/blob/ac0dcc9a63dc2a0edc62f8f1381b15b0b5ce5da3/NEWS#L37-L42
zle_highlight+=(paste:none)

# https://gist.github.com/magicdude4eva/2d4748f8ef3e6bf7b1591964c201c1ab

# This speeds up pasting w/ autosuggest
# https://github.com/zsh-users/zsh-autosuggestions/issues/276
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic
}

pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}

zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish
zstyle :bracketed-paste-magic active-widgets '.self-*'
EOF
    zcompile -UR ${target}
  fi
  source ${target}
}