## @file    $XDG_DATA_HOME/bash/lib/colors.sh
## @brief   Color terminal support.
## @author  Vasiliy Polyakov
## @date    2019
## @pre     lib.bash  (Bash scripting library).
## @pre     ncurses   (tput).

import_once || return $(($?-1))

if ! type -p tput >/dev/null || [[ $1 == '0' ]]; then
  declare -gir COLORS=0
  declare -gr SGR0=''
  SGR() { :; }
  return 0
fi

declare -gir COLORS="$(tput colors)"
declare -gr  SGR0=$'\e[m'

_colors::to_attr() {
  local OPT OPTARG
  local -i OPTIND color bg=0

  while getopts ':bf' OPT; do
    case $OPT in
      f) bg=0  ;;
      b) bg=10 ;;
    esac
  done; shift $(( OPTIND - 1 ))

  color="$1"

  if (( color < 8 && color >= 0 )); then
    echo $(( color + 30 + bg ))
  elif (( color < 16 )); then
    echo $(( color + 82 + bg ))
  elif (( color < 256 )); then
    echo $(( 38 + bg )) 5 $color
  fi
}

SGR() {
  local OPT OPTARG E='-e' P0='' P1=''
  local -i OPTIND
  local -a A C C8 C16 C256
  
  while getopts ':Ep' OPT; do
    case $OPT in
      E) E='' ;;
      p) P0='\[' P1='\]' ;;
    esac
  done; shift $(( OPTIND - 1 ))

  while (( $# )); do
    case $1 in
      fg=+([0-9])) C+=($(_colors::to_attr -f "${1#*=}")) ;;
      bg=+([0-9])) C+=($(_colors::to_attr -b "${1#*=}")) ;;
      fg8=+([0-9])) C8+=($(_colors::to_attr -f "${1#*=}")) ;;
      bg8=+([0-9])) C8+=($(_colors::to_attr -b "${1#*=}")) ;;
      fg16=+([0-9])) C16+=($(_colors::to_attr -f "${1#*=}")) ;;
      bg16=+([0-9])) C16+=($(_colors::to_attr -b "${1#*=}")) ;;
      fg256=+([0-9])) C256+=($(_colors::to_attr -f "${1#*=}")) ;;
      bg256=+([0-9])) C256+=($(_colors::to_attr -b "${1#*=}")) ;;
      fg=@(default|def|d)) A+=(39) ;;
      bg=@(default|def|d)) A+=(49) ;;
      reset|r) A+=(0) ;;
      bold|b) A+=(1) ;;
      dim) A+=(2) ;;
      italics|i) A+=(3) ;;
      underline|undescore|uline|ul|u) A+=(4) ;;
      blink) A+=(5) ;;
      reverse|inverse) A+=(7) ;;
      normal|n) A+=(22) ;;
      +([0-9])) A+=($1)
    esac; shift
  done
  
  local -n c="C$COLORS"
  if (( ${#c[@]} )); then
    A+=("${c[@]}")
  else
    A+=("${C[@]}")
  fi
  
  if (( ${#A[@]} )); then
    local IFS=';'
    echo -n $E "$P0\e[${A[*]}m$P1"
  fi
}

