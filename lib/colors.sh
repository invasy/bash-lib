## @file    $XDG_DATA_HOME/bash/lib/colors.sh
## @brief   Color terminal support.
## @author  Vasiliy Polyakov
## @date    2019
## @pre     lib.bash   (Bash scripting library).
## @pre     ncurses    (tput).

import_once || return $?

declare -gi COLORS="$(tput colors)"
declare -ga FG BG
declare -gr SGR0=$'\e[m'

local -i c
for (( c = 0; c < 8 && COLORS >= 8; c++ )); do
  FG[c]=$'\e'"[$((30+c))m"
  BG[c]=$'\e'"[$((40+c))m"
done
for (( c = 8; c < 16 && COLORS >= 16; c++ )); do
  FG[c]=$'\e'"[$((82+c))m"
  BG[c]=$'\e'"[$((92+c))m"
done
for (( c = 16; c < 256 && COLORS >= 256; c++ )); do
  FG[c]=$'\e'"[38;5;${c}m"
  BG[c]=$'\e'"[48;5;${c}m"
done
