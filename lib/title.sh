## # Terminal and window titles
##
## Copyright © 2014-2022 [Vasiliy Polyakov](mailto:bash@invasy.dev).
##
## ## Prerequisites
## - `lib.bash` - Bash scripting library;
## - `ncurses` — `tput`.
##
# TODO: add documentation

bash_lib || return $(($?-1))
type -p tput &>/dev/null || return 1

title() {
  local tsl=$'\e]2;' fsl='' title

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

# vim: set et sw=2 ts=2 fdm=marker fmr=@{,@}:
