## @file    $XDG_DATA_HOME/bash/lib/colors.sh
## @brief   Color terminal support.
## @author  Vasiliy Polyakov
## @date    2019
## @pre     lib.bash  (Bash scripting library).
## @pre     ncurses   (tput).

import_once || return $?

declare -gi COLORS
declare -ga FG BG
declare -gA SGR

local -i terminfo=0 c
case $1 in
  0) declare -r COLORS FG BG SGR; return 0 ;;
  terminfo) terminfo=1 ;;
esac

COLORS="$(tput colors)"

if (( terminfo )); then
  for (( c = 0; c < COLORS; c++ )); do
    FG[c]="$(tput setaf "$c")"
    BG[c]="$(tput setab "$c")"
  done
  SGR[bold]="$(tput bold)"
  SGR[dim]="$(tput dim)"
  SGR[italics]="$(tput sitm)"
  SGR[uline]="$(tput smul)"
  SGR[blink]="$(tput blink)"
  SGR[reverse]="$(tput rev)"
  SGR[reset]="$(tput sgr0)"
else
  local CSI=$'\e['
  for (( c = 0; c < 8 && COLORS >= 8; c++ )); do
    FG[c]="${CSI}$((30+c))m"
    BG[c]="${CSI}$((40+c))m"
  done
  for (( c = 8; c < 16 && COLORS >= 16; c++ )); do
    FG[c]="${CSI}$((82+c))m"
    BG[c]="${CSI}$((92+c))m"
  done
  for (( c = 16; c < 256 && COLORS >= 256; c++ )); do
    FG[c]="${CSI}38;5;${c}m"
    BG[c]="${CSI}48;5;${c}m"
  done
  SGR[bold]="${CSI}1m"
  SGR[dim]="${CSI}2m"
  SGR[italics]="${CSI}3m"
  SGR[uline]="${CSI}4m"
  SGR[blink]="${CSI}5m"
  SGR[reverse]="${CSI}7m"
  SGR[reset]="${CSI}m"
  unset CSI
fi; unset terminfo c
# TODO: add one-letter and digit aliases for SGR
SGR[rev]="${SGR[reverse]}"
SGR[exit]="${SGR[reset]}"
SGR[0]="${SGR[reset]}"

declare -r COLORS FG BG SGR
