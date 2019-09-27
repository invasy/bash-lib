#!/bin/bash
# vim: set ft=sh et sw=2 ts=2:

. "$(realpath -qe "$(dirname "${BASH_SOURCE[0]}")/../lib.bash")"
import colors

declare -a C=(0 1 2 3) C8=(8 1 2 3 4 5 6 7 8) C16=(16) C256=(256 1)
declare -n c="C0"
echo ${c[0]} ${#c[@]}

exit 0

declare -g _ret_func=''

fail() {
  false 1"2 3" 34
  success
  return 5
}

success() {
  :
  return 0
}

_err_trap() {
  local -i code="$1" line="$5"
  local cmd="$2" func="$3" file="$4"
  local msg="$(_ 'command %s exited with %d')"
  local -a args=("${cmd@Q}" "$code")

  if [[ $cmd == return* ]]; then
    msg="$(_ 'function %s() returned %d')"
    args=("$_ret_func" "$code")
  fi

  printf "error: $msg\n" "${args[@]}"
}

catch() {
  local a="$1"; shift
  local b="${*:-:}"
  
  echo "$b"
}

shopt -qso errtrace functrace
trap '_ret_func="${FUNCNAME[0]}"' RETURN
trap '_err_trap "$?" "$BASH_COMMAND" "${FUNCNAME[0]}" "${BASH_SOURCE[0]}" "$LINENO"' ERR
#declare -ft fail

success
fail
catch 1

