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

local -i arrays=0 funcs=0 terminfo=0
while (( $# )); do
  case $1 in
    0) declare -r COLORS=0 FG=() BG=() SGR=(); return 0 ;;
    funcs) funcs=1 ;;
    arrays) arrays=1 ;;
    terminfo) terminfo=1 ;;
  esac; shift
do

COLORS="$(tput colors)"

_colors::get() {
  
}

SGR() {
  local -i OPTIND
  local OPT OPTARG
  local -a a

  shopt -qs extglob
  while (( $# )); do
    case $1 in
      fg=+([0-9])) a+=() ;;
    esac; shift
  done
}

_colors::init_arrays() {
  local -i c

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
  fi
  # TODO: add one-letter and digit aliases for SGR
  SGR[rev]="${SGR[reverse]}"
  SGR[exit]="${SGR[reset]}"
  SGR[0]="${SGR[reset]}"
  SGR[1]="${SGR[bold]}"
}

colors::unset() {
  
}

declare -r COLORS FG BG SGR

