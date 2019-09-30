## @file    $XDG_DATA_HOME/bash/lib/title.sh
## @brief   Set terminal and window titles.
## @author  Vasiliy Polyakov
## @date    2019
## @pre     lib.bash  (Bash scripting library).
## @pre     ncurses   (tput).

bash_lib || return $(($?-1))
type -p tput &>/dev/null || return 1

title() {
  local tsl=$'\e]2;' fsl=$'\e\\' title

  title="$*"
  title="${title@Q}"
  title="${title//\'\\\'\'/\'}"
  title="${title//\\\'/\'}"
  if (( ${#title} > 1 )); then
    title="${title#?(\$)\'}"
    title="${title%\'}"
  fi
  
  printf "$tsl%s$fsl" "$title"
}
