## @file    $XDG_DATA_HOME/bash/lib/hooks.sh
## @brief   Bash hook functions (Zsh-like).
## @author  Vasiliy Polyakov
## @date    2015-2020
## @pre     bash             (GNU Bourne again shell).
## @pre     lib.bash         (Bash scripting library).
## @pre     gettext.sh       (i18n, optional).
## @pre     exceptions.bash  (exception handling).
## @todo    Rewrite this library.

bash_lib -n || return $(($?-1))

####  Constants  ##########################################################@{1
declare -gra _hooks=(precmd preexec)

####  Private functions  ##################################################@{1
_hook::init() {
  # shellcheck disable=SC2034
  declare -g BASH_HOOKS_SET=1
  declare -g PROMPT_COMMAND
  declare -ga precmd_functions preexec_functions

  local f_precmd='_hook::precmd'
  local f_preexec='_hook::preexec'

  # Set precmd hooks
  if [[ $PROMPT_COMMAND != *$f_precmd* ]]; then
    if [[ $PROMPT_COMMAND ]]; then
      PROMPT_COMMAND+=";$f_precmd"
    else
      PROMPT_COMMAND="$f_precmd"
    fi
  fi

  # Set preexec hooks
  # shellcheck disable=SC2064
  trap "$f_preexec" DEBUG
}

_hook::precmd() {
  local f

  for f in precmd "${precmd_functions[@]}"; do
    [[ $(type -t "$f") == 'function' ]] && "$f"
  done

  declare -g _hook_interactive=1

  return 0
}

_hook::preexec() {
  (( COMP_LINE || BASH_SUBSHELL || ! _hook_interactive )) && return 0
  [[ $BASH_COMMAND == '_hook::precmd' ]] && return 0

  shopt -qs extglob
  # shellcheck disable=SC2155
  local f h="$(HISTTIMEFORMAT='' history 1)"
  h="${h/*( )*([0-9])*( )}"

  for f in preexec "${preexec_functions[@]}"; do
    [[ $(type -t "$f") == 'function' ]] && "$f" "$h"
  done

  declare -g _hook_interactive=

  return 0
}

## Throw an exception from @c hook::* functions.
## @param   $1  Error code (1..255).
## @param   $2  Error message format string.
## @param   $@  Message parameters.
## @return  Error code.
## @throw   Hook exception.
_hook::throw() {
  local code="$1" msg="$2"; shift 2
  throw -d 2 -f 'hook' -c "$code" "$msg" "$@"
}

_hook::help() {
  echo -ne "\
hook - manage Bash hook functions (Zsh-like).

Usage:
    hook [-a] <hook> <func_name>
        Set (add) specified function to <hook> array.
    hook -d <hook> <func_name>
        Unset hook function by name (literal match).
    hook -D <hook> <pattern>
        Unset all hook functions matching <pattern>.
    hook -L [pattern]
        List hook functions matching <pattern>.
        List all hook functions if <pattern> is not specified.
    hook -h
        Show this usage info and quit.
"
}

## Add (set) hook function.
## @param   $1  Hook name.
## @param   $2  Function name.
## @return  Nothing.
## @throw   UNDEF  Undefined function.
_hook::add() {
  local -n hook="${1}_functions"
  local func="$2"

  # Check if function is defined
  [[ $(type -t "$func") != 'function' ]] && \
    _hook::throw UNDEF "$(_ "undefined function '%s'")" "$func"

  if (( ${#hook[@]} )); then
    in_array "${!hook}" "$func" || hook+=("$func")
  else
    hook=("$func")
  fi
}

_hook::del() {
  # shellcheck disable=SC2178
  local -n hook="${1}_functions"
  local -- func="$2"
  local -i pattern="${3:-0}==2"

  if (( ${#hook[@]} )); then
    # shellcheck disable=SC2206
    (( pattern )) && hook=(${hook[@]/*$func*}) || hook=(${hook[@]/$func})
    (( ${#hook[@]} )) || unset hook
  fi
}

_hook::list() {
  if [[ $1 ]]; then
    declare -p "${1}_functions" 2>/dev/null
  else
    local h
    for h in "${_hooks[@]}"; do
      declare -p "${h}_functions" 2>/dev/null
    done
  fi
}

hook() {
  local -i OPTIND r=0 del=0 list=0 help=0
  local -- OPT OPTARG

  # Parse options and arguments
  while getopts ":adDLh" OPT; do
    case "$OPT" in
      d)  del=1;  break ;;
      D)  del=2;  break ;;
      L)  list=1; break ;;
      h)  help=1; break ;;
      \?) hook::throw USAGE "$(_ "invalid option '%s'")" "$OPTARG" ;;
      *)  break
    esac
  done; shift $(( OPTIND - 1 ))

  (( help || ! $# )) && { _hook::help; return 0; }
  (( list )) && { _hook::list "$1"; return $?; }
  [[ ! $1 ]] && _hook::throw USAGE "$(_ 'arg 1: missing hook name')"
  [[ ! $2 ]] && _hook::throw USAGE "$(_ 'arg 2: missing function name')"
  in_array _hooks "$1" || _hook::throw HOOK "$(_ "unknown hook '%s'")" "$1"
  if (( del )); then
    _hook::del "$1" "$2" "$del"
  else
    _hook::add "$1" "$2"
  fi
}

_hook::init

# vim: set et sw=2 ts=2 ft=sh fen fdm=marker fmr=@{,@}:
