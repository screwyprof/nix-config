# Initialize navi widget for zsh
if [[ $options[zle] = on ]]; then
  eval "$(navi widget zsh)"
fi

# Use Ctrl+G to trigger navi widget
bindkey '^G' _navi_widget