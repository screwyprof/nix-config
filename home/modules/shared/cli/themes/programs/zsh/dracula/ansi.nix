{ config, ... }:

let
  inherit (config.colorScheme) palette;
  inherit (config.lib.theme) formatRGB;

  # Generate ANSI escape sequences
  ansiSequences = ''
    # Dracula
    # Set all 16 colors at once (0-15) plus foreground, background, and cursor colors
    printf "\033]4;0;#${palette.base00};1;#${palette.base08};2;#${palette.base0B};3;#${palette.base0A};4;#${palette.base0D};5;#${palette.base0E};6;#${palette.base0C};7;#${palette.base05};8;#${palette.base03};9;#${palette.base08};10;#${palette.base0B};11;#${palette.base0A};12;#${palette.base0D};13;#${palette.base0E};14;#${palette.base0C};15;#${palette.base07}\007"
    printf "\033]10;#${palette.base05};#${palette.base00};#${palette.base05}\007"  # foreground;background;cursor
    printf "\033]17;#${palette.base02}\007"  # selection background
    printf "\033]19;#${palette.base05}\007"  # selected text
    printf "\033]5;0;#${palette.base05}\007" # bold text

    # Terminal-specific escape sequence handling
    if [ -z "''${TTY}" ] && ! TTY=$(tty); then
      put_template() { true; }
      put_template_var() { true; }
      put_template_custom() { true; }
    elif [ -n "''${TMUX}" ] || [ "''${TERM%%[-.]*}" = "tmux" ]; then
      # Tell tmux to pass the escape sequences through
      put_template() { printf '\033Ptmux;\033\033]4;%d;rgb:%s\033\033\\\033\\' "$@" > "''${TTY}"; }
      put_template_var() { printf '\033Ptmux;\033\033]%d;rgb:%s\033\033\\\033\\' "$@" > "''${TTY}"; }
      put_template_custom() { printf '\033Ptmux;\033\033]%s%s\033\033\\\033\\' "$@" > "''${TTY}"; }
    elif [ "''${TERM%%[-.]*}" = "screen" ]; then
      # GNU screen (screen, screen-256color, screen-256color-bce)
      put_template() { printf '\033P\033]4;%d;rgb:%s\007\033\\' "$@" > "''${TTY}"; }
      put_template_var() { printf '\033P\033]%d;rgb:%s\007\033\\' "$@" > "''${TTY}"; }
      put_template_custom() { printf '\033P\033]%s%s\007\033\\' "$@" > "''${TTY}"; }
    elif [ "''${TERM%%-*}" = "linux" ]; then
      put_template() { [ "$1" -lt 16 ] && printf "\e]P%x%s" "$1" "$(echo "$2" | sed 's/\///g')" > "''${TTY}"; }
      put_template_var() { true; }
      put_template_custom() { true; }
    else
      put_template() { printf '\033]4;%d;rgb:%s\033\\' "$@" > "''${TTY}"; }
      put_template_var() { printf '\033]%d;rgb:%s\033\\' "$@" > "''${TTY}"; }
      put_template_custom() { printf '\033]%s%s\033\\' "$@" > "''${TTY}"; }
    fi

    # 16 color space
    put_template 0  "${formatRGB palette.ansiBlack}"        # Black
    put_template 1  "${formatRGB palette.ansiRed}"          # Red
    put_template 2  "${formatRGB palette.ansiGreen}"        # Green
    put_template 3  "${formatRGB palette.ansiYellow}"       # Yellow
    put_template 4  "${formatRGB palette.ansiBlue}"         # Blue
    put_template 5  "${formatRGB palette.ansiMagenta}"      # Magenta
    put_template 6  "${formatRGB palette.ansiCyan}"         # Cyan
    put_template 7  "${formatRGB palette.ansiWhite}"        # White

    # Bright colors
    put_template 8  "${formatRGB palette.ansiBrightBlack}"  # Bright Black
    put_template 9  "${formatRGB palette.ansiBrightRed}"    # Bright Red
    put_template 10 "${formatRGB palette.ansiBrightGreen}"  # Bright Green
    put_template 11 "${formatRGB palette.ansiBrightYellow}" # Bright Yellow
    put_template 12 "${formatRGB palette.ansiBrightBlue}"   # Bright Blue
    put_template 13 "${formatRGB palette.ansiBrightMagenta}"# Bright Magenta
    put_template 14 "${formatRGB palette.ansiBrightCyan}"   # Bright Cyan
    put_template 15 "${formatRGB palette.ansiBrightWhite}"  # Bright White

    # Special handling for iTerm2
    if [ -n "$ITERM_SESSION_ID" ]; then
      # iTerm2 proprietary escape codes
      put_template_custom Pg ${palette.base05} # foreground
      put_template_custom Ph ${palette.base00} # background
      put_template_custom Pi ${palette.base05} # bold color
      put_template_custom Pj ${palette.base02} # selection color
      put_template_custom Pk ${palette.base05} # selected text color
      put_template_custom Pl ${palette.base05} # cursor
      put_template_custom Pm ${palette.base00} # cursor text
    else
      put_template_var 10 "${formatRGB palette.base05}" # foreground
      put_template_var 11 "${formatRGB palette.base00}" # background
      put_template_custom 12 ";7" # cursor (reverse video)
    fi

    # Clean up
    unset -f put_template
    unset -f put_template_var
    unset -f put_template_custom
  '';
in
{
  programs.zsh = {
    initExtra = ansiSequences;
  };
}
