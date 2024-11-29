() {
  local -r target=${ZIM_HOME:-${ZDOTDIR:-$HOME/.zim}}/modules/thefuck/init.zsh
  
  # Check if thefuck is installed
  (( ${+commands[thefuck]} )) || return 1
  
  if [[ ! ( -s ${target} && ${target} -nt ${commands[thefuck]} ) ]]; then
    mkdir -p ${target:h}
    # Generate the lazy loading functions
    cat >! ${target} << 'EOL'
    # Define the function that will be called on first use
    thefuck-init() {
      unfunction fuck
      eval "$(thefuck --alias)"
      # Call the newly defined function
      fuck "$@"
    }

    # Create placeholder function
    fuck() {
      thefuck-init "$@"
    }

    # Define the widget without running thefuck --alias
    function fuck-command-line() {
      BUFFER="fuck"
      zle accept-line
    }
    zle -N fuck-command-line
    
    # Use Ctrl+x,f
    bindkey '^Xf' fuck-command-line
    bindkey '\ef' fuck-command-line
EOL
    zcompile -UR ${target}
  fi
  source ${target}
} ${0:h}/init.zsh || return 1