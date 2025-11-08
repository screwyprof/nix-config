{ config, ... }:

{
  iterm2Colors = ''
    printf "\033]P0${config.colorScheme.palette.ansiBlack}\033\\" # black
    printf "\033]P1${config.colorScheme.palette.ansiRed}\033\\" # red
    printf "\033]P2${config.colorScheme.palette.ansiGreen}\033\\" # green
    printf "\033]P3${config.colorScheme.palette.ansiYellow}\033\\" # yellow
    printf "\033]P4${config.colorScheme.palette.ansiBlue}\033\\" # blue
    printf "\033]P5${config.colorScheme.palette.ansiMagenta}\033\\" # magenta
    printf "\033]P6${config.colorScheme.palette.ansiCyan}\033\\" # cyan
    printf "\033]P7${config.colorScheme.palette.ansiWhite}\033\\" # white
    printf "\033]P8${config.colorScheme.palette.ansiBrightBlack}\033\\" # bright black
    printf "\033]P9${config.colorScheme.palette.ansiBrightRed}\033\\" # bright red
    printf "\033]Pa${config.colorScheme.palette.ansiBrightGreen}\033\\" # bright green
    printf "\033]Pb${config.colorScheme.palette.ansiBrightYellow}\033\\" # bright yellow
    printf "\033]Pc${config.colorScheme.palette.ansiBrightBlue}\033\\" # bright blue
    printf "\033]Pd${config.colorScheme.palette.ansiBrightMagenta}\033\\" # bright magenta
    printf "\033]Pe${config.colorScheme.palette.ansiBrightCyan}\033\\" # bright cyan
    printf "\033]Pf${config.colorScheme.palette.ansiBrightWhite}\033\\" # bright white
    printf "\033]Pg${config.colorScheme.palette.base05}\033\\" # foreground
    printf "\033]Ph${config.colorScheme.palette.base00}\033\\" # background
    printf "\033]Pl${config.colorScheme.palette.base05}\033\\" # cursor
    printf "\033]Pj${config.colorScheme.palette.base02}\033\\" # selection color
    printf "\033]Pk${config.colorScheme.palette.base05}\033\\" # selected text
    printf "\033]Pi${config.colorScheme.palette.base05}\033\\" # bold
  '';
}
