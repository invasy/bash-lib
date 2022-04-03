## @file    $XDG_DATA_HOME/bash/lib/exceptions.sh
## @brief   Bash exception handling.
## @author  Vasiliy Polyakov
## @date    2016-2020
## @pre     lib.bash     (Bash scripting library).
## @pre     sysexits.sh  (exit/return code constants).

bash_lib || return $(($?-1))

####  Private functions  ##################################################@{1
# shellcheck disable=SC1004
_exceptions::init() {
  # shellcheck disable=SC2034
  declare -gi EXCEPTIONS_ERREXIT="${1:-0}"  ##< Throw exception if there is non-zero status.

  declare -gA _error             ##< Error info. Set by ERR trap handler.
  _error[code]=0                 ##< Exit/return code (0..255) (@see sysexits.bash).
  _error[source]=''              ##< Source file where error occured.
  _error[func]=''                ##< Function where error occured.
  _error[line]=0                 ##< Line number where error occured.
  _error[cmd]=''                 ##< Errorous command.

  declare -gA _exc               ##< Exception info. Set by @c throw function.
  _exc[code]=0                   ##< Exit/return code (0..255) (@see sysexits.bash).
  _exc[msg]=''                   ##< Textual error message.
  _exc[func]=''                  ##< Function name.
  _exc[source]=''                ##< Script filename.
  _exc[line]=0                   ##< Line number.
  _exc[handled]=0                ##< Exception handled.
  _exc[continue]=0               ##< Continue execution.

  declare -ga _exc_args=()       ##< Error message arguments.
  declare -ga _exc_callstack=()  ##< Function calls stack.
  declare -ga _exc_patterns=()   ##< Exception match patterns.
  declare -ga _exc_handlers=()   ##< Exception handlers.

  declare -gr _exc_initfunc="${FUNCNAME[3]}"  ##< Initial function name.

  declare -gi _try_level=0
  declare -ga _try_source=''
  declare -ga _try_func=''
  declare -ga _try_line=''

  # Set options
  shopt -qso errtrace
  # Set ERR trap
  trap '_error[code]=$? _error[line]="$LINENO" _error[cmd]="$BASH_COMMAND"
_error[func]="${FUNCNAME[0]}" _error[source]="${BASH_SOURCE[0]}"
if (( EXCEPTIONS_ERREXIT && ! _exc[code] )); then
  if [[ ${_error[cmd]} == return* ]]; then
    throw -0 -c ${_error[code]} -l "${_error[line]}" \
          "$(_ "function '\''%s'\'' got return code %i")" \
          "${FUNCNAME[0]}" "${_error[code]}"
  else
    throw -0 -c ${_error[code]} -l "${_error[line]}" \
          "$(_ "command '\''%s'\'' returned %i")" \
          "${_error[cmd]}" "${_error[code]}"
  fi
fi
if (( _exc[code] != 0 )); then
  if (( ! _exc[handled] )); then
    eval "$(_exceptions::handler)" || :
    _exc[handled]=1
  fi
  (( _try_level )) && __="${_try_func[_try_level]}" || __="$_exc_initfunc"
  if (( ! _exc[continue])); then
    if [[ ${_error[func]} == "$__" ]]; then
      ((_try_level)) && { _exc[code]=0; break 9000; } || exit ${_exc[code]}
    else
      return ${_exc[code]}
    fi
  fi
fi' ERR
}

_exceptions::match() {
  [[ $1 == 'all' || $1 == '*' ]] && return 0

  local n c conditions=0  # Sic! It's a zero here. Don't touch!

  for n in ${1//*([ 	]);*([ 	])/ }; do
    case $n in
      $EX_NAMES) c="(_exc[code]==${EX[$n]})" ;;
      +([0-9]))  c="(_exc[code]==$n)"        ;;
      +([0-9])*([ 	])-*([ 	])+([0-9]))
        c="(_exc[code]>=${n%%*([ \t])-*([ \t])+([0-9])}&&"
        c+="_exc[code]<=${n##+([0-9])*([ \t])-*([ \t])})"
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

  for (( n = 0; n < ${#_exc_patterns[@]}; n++ )); do
    if _exceptions::match "${_exc_patterns[n]}"; then
      echo "${_exc_handlers[n]}"
      return 0
    fi
  done

  # Default exception handler.
  local name="${_exc[func]}"
  if [[ $name == 'main' ]]; then
    name="${_exc[source]##*/}"
  else
    name+='()'
  fi
  echo "confess '$name'"

  return 0
}

# shellcheck disable=SC2034
_exceptions::try() {
  (( _try_level++ ))
  _try_source[_try_level]="${BASH_SOURCE[1]}"
  _try_func[_try_level]="${FUNCNAME[1]}"
  _try_line[_try_level]="${BASH_LINENO[0]}"

  _exc[code]=0 _exc_patterns=() _exc_handlers=()

  return 0
}

_exceptions::end_try() {
  (( _try_level )) || return "${EX[SOFTWARE]}"

  unset '_try_source[_try_level]' '_try_func[_try_level]' '_try_line[_try_level]'
  (( _try_level-- ))

  _exc_patterns=() _exc_handlers=()

  return 0
}

####  Exported functions and aliases  #####################################@{1
alias try='_exceptions::try; while true; do '
alias end_try='break; done; _exceptions::end_try '

catch() {
  if (( _try_level == 0 )); then
    return "${EX[SOFTWARE]}"
  elif [[ -z $1 || -z $2 ]]; then
    return "${EX[USAGE]}"
  fi

  _exc_patterns+=("$1"); shift
  _exc_handlers+=("${*:-:}")

  return 0
}

throw() {
  local -- OPT OPTARG r=
  local -i OPTIND OPTERR=0 depth=1 i

  # Default values for exception parameters
  _exc[code]=1 _exc[continue]=0 _exc[handled]=0
  _exc[msg]='' _exc[arg]='' _exc[source]='' _exc[func]='' _exc[line]=''
  _exc_callstack=()

  # Process options
  while getopts ':0c:d:f:l:s:' OPT; do
    case $OPT in
      0) r=0 ;;
      d) depth="$OPTARG" ;;
      s) _exc[source]="$OPTARG" ;;
      f) _exc[func]="$OPTARG" ;;
      l) _exc[line]="$OPTARG" ;;
      c)
        case $OPTARG in
          $EX_NAMES) _exc[code]="${EX[$OPTARG]}" ;;
          +([0-9]))  _exc[code]="$OPTARG"        ;;
        esac ;;
      :)  echo "throw: missing argument for '-$OPTARG'" >&2; return "${EX[USAGE]}" ;;
      \?) echo "throw: invalid argument '-$OPTARG'" >&2; return "${EX[USAGE]}" ;;
      *)  echo "throw: cannot parse arguments" >&2; return "${EX[USAGE]}" ;;
    esac
  done
  (( OPTIND > 1 )) && shift $(( OPTIND - 1 ))

  if (( depth >= 1 )); then
    : "${_exc[source]:=${BASH_SOURCE[depth]}}"
    : "${_exc[func]:=${FUNCNAME[depth]}}"
    : "${_exc[line]:=${BASH_LINENO[depth-1]}}"
  fi

  # Error message (format string).
  _exc[msg]="$1"; shift
  # Additional message arguments.
  _exc_args=("$@")

  # Save call stack
  for (( i = depth; i < ${#FUNCNAME[@]} - 1; i++ )); do
    if [[ ${FUNCNAME[i+1]} == '_exceptions::end_try' ]]; then
      _exc_callstack+=(
        "${FUNCNAME[i]}#${FUNCNAME[i+1]}#${_try[line]}#${BASH_SOURCE[i+2]}")
      (( i++ )) || :
    else
      _exc_callstack+=(
        "${FUNCNAME[i]}#${FUNCNAME[i+1]}#${BASH_LINENO[i]}#${BASH_SOURCE[i+1]}")
    fi
  done

  return ${r:-${_exc[code]}}
}

perror() {
  (( _exc[code] )) || return 0

  local source='' msg

  if [[ $1 == '-s' ]]; then
    source=" <${_exc[code]}> at '$(relpath "${_exc[source]}")':${_exc[line]}"
    shift
  fi

  # shellcheck disable=SC2059
  msg="$(printf "${_exc[msg]}" "${_exc_args[@]}")"
  echo -e "${1:+$1: }$msg$source" >&2

  return 0
}

confess() {
  (( _exc[code] )) || return 0

  local func caller s=''

  perror -s "$1"
  for func in "${_exc_callstack[@]}"; do
    s+="  "
    if [[ $func =~ ^([^#]+)#([^#]+)#([0-9]+)#(.*)$ ]]; then
      caller="${BASH_REMATCH[2]}"
      s+="${BASH_REMATCH[1]}() called"
      if [[ $caller != 'main' ]]; then
        s+=" from $caller()"
      fi
      s+=" at '$(relpath "${BASH_REMATCH[4]}")':${BASH_REMATCH[3]}"
    else
      s+="$func"
    fi
    s+="\n"
  done
  [[ -n $s ]] && echo -ne "$s" >&2

  return 0
}

_exceptions::init "$@"

# vim: set et sw=2 ts=2 fdm=marker fmr=@{,@}: