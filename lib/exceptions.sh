## @file    $XDG_DATA_HOME/bash/lib/exceptions.sh
## @brief   Bash exception handling.
## @author  Vasiliy Polyakov
## @date    2016-2019
## @pre     bash           (GNU Bourne again shell).
## @pre     lib.bash       (Bash scripting library).
## @pre     sysexits.bash  (exit/return code constants).

source_guard || return $?
use sysexits

####  Private functions  ##################################################@{1
_exceptions::init() {
  ## Throw exception if there is non-zero status.
  declare -gi EXCEPTIONS_ERREXIT="${1:-0}"

  declare -gA _err  ##< Error info.
  _err[code]=0      ##< Exit/return code (0..255) (@see sysexits.bash).
  _err[source]=''   ##< Source file where error occured.
  _err[func]=''     ##< Function where error occured.
  _err[line]=0      ##< Line number where error occured.
  _err[cmd]=''      ##< Errorous command.

  declare -gA _ex   ##< Exception info.
  _ex[code]=0       ##< Exit/return code (0..255) (@see sysexits.bash).
  _ex[msg]=''       ##< Textual error message.
  _ex[func]=''      ##< Function name.
  _ex[source]=''    ##< Script filename.
  _ex[line]=0       ##< Line number.
  _ex[handled]=0    ##< Exception handled.
  _ex[continue]=0   ##< Continue execution.

  declare -ga _ex_args=()       ##< Error message arguments.
  declare -ga _ex_callstack=()  ##< Function calls stack.
  declare -ga _ex_patterns=()   ##< Exception match patterns.
  declare -ga _ex_handlers=()   ##< Exception handlers.

  declare -g _ex_initfunc="${FUNCNAME[3]}"  ##< Initial function name.

  declare -gi _try_level=0
  declare -ga _try_source=''
  declare -ga _try_func=''
  declare -ga _try_line=''

  # Set options
  shopt -qso errtrace
  # Set ERR trap
  trap '_err[code]=$? _err[line]="$LINENO" _err[cmd]="$BASH_COMMAND"
_err[func]="${FUNCNAME[0]}" _err[source]="${BASH_SOURCE[0]}"
(( EXCEPTIONS_ERREXIT && ! _ex[code] )) && {
  [[ ${_err[cmd]} == return* ]] && \
    throw -0 -c ${_err[code]} -l "${_err[line]}" \
          "$(_ "function '\''%s'\'' got return code %i")" \
          "${FUNCNAME[0]}" "${_err[code]}" || \
    throw -0 -c ${_err[code]} -l "${_err[line]}" \
          "$(_ "command '\''%s'\'' returned %i")" \
          "${_err[cmd]}" "${_err[code]}"; }
if (( _ex[code] )); then
  if (( ! _ex[handled] )); then
    eval "$(_exceptions::handler)" || :
    _ex[handled]=1
  fi
  (( _try_level )) && __="${_try_func[_try_level]}" || __="$_ex_initfunc"
  if (( ! _ex[continue])); then
    if [[ ${_err[func]} == "$__" ]]; then
      ((_try_level)) && { _ex[code]=0; break 9000; } || exit ${_ex[code]}
    else
      return ${_ex[code]}
    fi
  fi
fi' ERR
}

_exceptions::match() {
  [[ $1 == 'all' || $1 == '*' ]] && return 0

  local n c conditions=0  # Sic! It's a zero here.

  for n in ${1//*([ \t]);*([ \t])/ }; do
    case $n in
      $EX_NAMES) c="(_ex[code]==${EX[$n]})" ;;
      +([0-9]))  c="(_ex[code]==$n)"        ;;
      +([0-9])*([ \t])-*([ \t])+([0-9]))
        c="(_ex[code]>=${n%%*([ \t])-*([ \t])+([0-9])}&&"
        c+="_ex[code]<=${n##+([0-9])*([ \t])-*([ \t])})"
        ;;
      *) continue
    esac
    [[ $conditions ]] && conditions+='||'
    conditions+="$c"
  done

  eval "(($conditions))"
}

_exceptions::handler() {
  local -i n

  for (( n = 0; n < ${#_ex_patterns[@]}; n++ )); do
    if _exceptions::match "${_ex_patterns[n]}"; then
      echo "${_ex_handlers[n]}"
      return 0
    fi
  done

  # Default exception handler.
  local name="${_ex[func]}"
  [[ $name == 'main' ]] && name="${_ex[source]##*/}"
  echo "confess '${_ex[func]}()'"

  return 0
}

_exceptions::try() {
  (( _try_level++ ))
  _try_source[_try_level]="${BASH_SOURCE[1]}"
  _try_func[_try_level]="${FUNCNAME[1]}"
  _try_line[_try_level]="${BASH_LINENO[0]}"

  _ex[code]=0 _ex_patterns=() _ex_handlers=()

  return 0
}

_exceptions::end_try() {
  (( _try_level )) || return ${EX[SOFTWARE]}

  _try_source[_try_level]= _try_func[_try_level]= _try_line[_try_level]=
  (( _try_level-- ))

  _ex_patterns=() _ex_handlers=()

  return 0
}

####  Exported functions and aliases  #####################################@{1
alias try='_exceptions::try; while true; do '
alias end_try='break; done; _exceptions::end_try '

catch() {
  (( _try_level )) || return ${EX[SOFTWARE]}
  [[ $1 && $2 ]] || return ${EX[USAGE]}

  _ex_patterns+=("$1"); shift
  _ex_handlers+=("${*:-:}")

  return 0
}

throw() {
  local -- OPT OPTARG k r=
  local -i OPTIND depth=1 i

  # Default values for exception parameters
  _ex[code]=1 _ex[continue]=0 _ex[handled]=0
  _ex[msg]= _ex[arg]= _ex[source]= _ex[func]= _ex[line]=
  _ex_callstack=()

  # Process options
  while getopts ':0c:d:f:l:s:' OPT; do
    case $OPT in
      0) r=0 ;;
      d) depth="$OPTARG" ;;
      s) _ex[source]="$OPTARG" ;;
      f) _ex[func]="$OPTARG"   ;;
      l) _ex[line]="$OPTARG"   ;;
      c)
        case $OPTARG in
          $EX_NAMES) _ex[code]="${EX[$OPTARG]}" ;;
          +([0-9]))  _ex[code]="$OPTARG"        ;;
        esac
    esac
  done
  (( OPTIND > 1 )) && shift $(( OPTIND - 1 ))

  if (( depth >= 1 )); then
    : ${_ex[source]:=${BASH_SOURCE[depth]}}
    : ${_ex[func]:=${FUNCNAME[depth]}}
    : ${_ex[line]:=${BASH_LINENO[depth-1]}}
  fi

  # Error message (format string).
  _ex[msg]="$1"; shift
  # Additional message arguments.
  _ex_args=("$@")

  # Save call stack
  for (( i = depth; i < ${#FUNCNAME[@]} - 1; i++ )); do
    if [[ ${FUNCNAME[i+1]} == '_exceptions::end_try' ]]; then
      _ex_callstack+=(
        "${FUNCNAME[i]}#${FUNCNAME[i+1]}#${_try[line]}#${BASH_SOURCE[i+2]}")
      (( i++ )) || :
    else
      _ex_callstack+=(
        "${FUNCNAME[i]}#${FUNCNAME[i+1]}#${BASH_LINENO[i]}#${BASH_SOURCE[i+1]}")
    fi
  done

  return ${r:-${_ex[code]}}
}

perror() {
  (( _ex[code] )) || return 0

  local source= msg

  if [[ $1 == '-s' ]]; then
    source=" <${_ex[code]}> at '$(relpath "${_ex[source]}")':${_ex[line]}"
    shift
  fi

  msg="$(printf "${_ex[msg]}" "${_ex_args[@]}")"
  echo -e "${1:+$1: }$msg$source" >&2

  return 0
}

confess() {
  (( _ex[code] )) || return 0

  local func caller s=

  perror -s "$1"
  for func in "${_ex_callstack[@]}"; do
    s+="  "
    if [[ $func =~ ^([^#]+)#([^#]+)#([0-9]+)#(.*)$ ]]; then
      caller="${BASH_REMATCH[2]}"
      s+="${BASH_REMATCH[1]}() called"
      [[ $caller != 'main' ]] && s+=" from $caller()"
      s+=" at '$(relpath "${BASH_REMATCH[4]}")':${BASH_REMATCH[3]}"
    else
      s+="$func"
    fi
    s+="\n"
  done
  [[ -n $s ]] && echo -ne "$s" >&2

  return 0
}

_exceptions::init

# vim: set et sw=2 ts=2 fen fdm=marker fmr=@{,@}:
