## @file    $XDG_DATA_HOME/bash/lib/debug.sh
## @brief   Bash scripts debugging library.
## @author  Vasiliy Polyakov
## @date    2016-2019
## @pre     bash           (GNU Bourne again shell).
## @pre     lib.bash       (Bash scripting library).
## @pre     sysexits.bash  (exit/return codes).

source_guard || return $?
use hooks

####  Variables  ##########################################################@{1
declare -gi DEBUG  ##< Debugging level.
[[ $1 == +([0-9]) ]] && DEBUG="$1"

## @Array  _trace  Function tracing info.
## @key    on      Function tracing is in progress.
## @key    traps   Saved shell traps.
## @key    opts    Saved shell options.
## @key    depth   Call stack depth.
## @key    cmd     Current command.
## @key    ret     Current return/exit code.

####  Private functions  ##################################################@{1
_trace::callstack() {
  local stack func sep='->'
  local -i i

  for (( i = ${#FUNCNAME[@]} - 1; i > 0; i-- )); do
    func="${FUNCNAME[i]}"
    [[ $func == 'main' ]] && func="${BASH_SOURCE[i]}"
    (( i > 1 )) && func+=":${BASH_LINENO[i-1]}"
    stack="${stack:+$stack$sep}$func"
  done

  echo "$stack"
}

_trace::enter() {
  (( ! _trace[on] )) && return ${EX[SOFTWARE]}

  [[ ${BASH_COMMAND#${FUNCNAME[1]}} == "$BASH_COMMAND" \
     || ${FUNCNAME[1]} == @(?(end_)trace|_trace::@(enter|leave|callstack)) ]] \
  && return 0

  local -a argv argr=("${BASH_ARGV[@]:BASH_ARGC[0]:BASH_ARGC[1]}")
  local -i i

  (( _trace[depth]++ ))

  for (( i = ${#argr[@]} - 1; i >= 0; i-- )); do
    argv+=("'${argr[i]}'")
  done
  if [[ ${FUNCNAME[2]} == 'main' ]]; then
    dbg "[%2i] -> %s(%s) called at '%s' line %i" \
        "${_trace[depth]}" "${FUNCNAME[1]}" "${argv[*]}" \
        "${BASH_SOURCE[2]}" "${BASH_LINENO[1]}"
  else
    dbg "[%2i] -> %s(%s) called from %s() at '%s' line %i" \
        "${_trace[depth]}" "${FUNCNAME[1]}" "${argv[*]}" \
        "${FUNCNAME[2]}" "${BASH_SOURCE[2]}" "${BASH_LINENO[1]}"
  fi

  return 0
}

_trace::leave() {
  (( ! _trace[on] )) && return ${EX[SOFTWARE]}

  [[ ${FUNCNAME[1]} == @(?(end_)trace|_trace::@(enter|leave)) ]] && return 0

  if [[ ${_trace[cmd]} == return\ * ]]; then
    eval "_trace[ret]=\"${_trace[cmd]##return+([ \t])}\""
  fi
  if [[ ${FUNCNAME[2]} == 'main' ]]; then
    dbg "[%2i] <- %s() returned %i" \
        "${_trace[depth]}" "${FUNCNAME[1]}" "${_trace[ret]}"
  else
    dbg "[%2i] <- %s() returned %i to %s()" \
        "${_trace[depth]}" "${FUNCNAME[1]}" \
        "${_trace[ret]}" "${FUNCNAME[2]}"
  fi

  (( _trace[depth]-- ))

  return 0
}

####  Exported functions  #################################################@{1
trace() {
  (( ! DEBUG    )) && return 0
  (( _trace[on] )) && return ${EX[SOFTWARE]}

  declare -gA _trace
  local k t

  _trace[on]=1 _trace[depth]=0

  # Save and set options
  for k in extglob extdebug; do
    _trace[opts]+="$(shopt -p "$k" 2>/dev/null);"
    shopt -qs "$k"
  done
  for k in functrace; do
    _trace[opts]+="$(shopt -po "$k" 2>/dev/null);"
    shopt -qso "$k"
  done

  # Save traps
  for k in DEBUG RETURN; do
    t="$(trap -p "$k" 2>/dev/null)"
    _trace[traps]+="${t:-trap - "$k"};"
  done

  # Set traps
  trap '_trace::enter' DEBUG
  trap '_trace[cmd]="$BASH_COMMAND" _trace[ret]="$?"; _trace::leave' RETURN

  return 0
}

end_trace() {
  (( ! _trace[on] )) && return ${EX[SOFTWARE]}

  # Restore traps and options
  eval "${_trace[traps]}${_trace[opts]}"

  # Unset trace variables
  unset _trace

  return 0
}

dbg() {
  if (( DEBUG )); then
    dbg() {
      local fmt="$1"; shift
      printf "DEBUG $fmt\n" "$@" >&2
    }
    dbg "$@"
  else
    dbg() { :; }
  fi
}

# vim: set et sw=2 ts=2 fen fdm=marker fmr=@{,@}:
