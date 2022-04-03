## @file    $XDG_DATA_HOME/bash/lib/json.sh
## @brief   JSON parser for Bash.
## @author  Vasiliy Polyakov
## @date    2016-2019
## @pre     bash         (GNU Bourne again shell).
## @pre     lib.bash     (Bash scripts library).
## @pre     gettext.sh   (i18n, optional).
## @pre     debug.bash   (debugging, optional).
## @pre     try.bash     (exception handling).
## @pre     arrays.bash  (multidimensional arrays).
## @note    Additional features: #-comments.
## @retval    0          OK
## @retval   64  load    command line usage error
## @retval   66  load    cannot read input file
## @retval  127  load    unknown command as a callback
## @retval   65  lexer   unexpected character
## @retval   65  parser  expected value
## @retval   65  parser  expected string
## @retval   65  parser  expected ':'
## @retval   65  parser  expected ',' or '}'
## @retval   65  parser  expected ',' or ']'
## @retval   65  parser  expected end of file
## @todo    rewrite this library, update for new `lib.bash`
## @todo    change callback signature to <callback> <level> <name> <keys> <type> [value]
##          (add @c level argument to callback functions).

bash_lib -n || return $(($?-1))

import debug
import try
import arrays

####  Constants  ###########################################################@{
# Regular expressions for tokens {{{2
# Token is the outermost match
declare -grA _json_regex=(
  [space]=$'([ \t]+)'
  [term]='([][{}:,#])'
  [number]='(-?(0|[1-9][0-9]*)(\.[0-9]*)?([eE][+-]?[0-9]*)?)'
  [string]='"(([^"\]|\\["\/abfnrt$]|\\u[0-9A-Fa-f]{4})*)"'
  [keyword]='(true|false|null)'
)

####  Variables  ###########################################################@{
# Parsing {{{2
#_json[done]  - parsing completed?
#_json[level] - current structure level
#_json[line]  - current parsed line

# Token {{{2
#_json_token[type] - type of a token: 'term', 'keyword', 'string', 'number' or 'space'
#_json_token[text] - textual content of a token

# Input file {{{2
#_json_file[name] - input JSON file name or 'stdin'
#_json_file[line] - current line number
#_json_file[char] - current char number in line

# Output array {{{2
#_json_array[name] - name of an array variable to load JSON data to
#_json_array[keys] - keys of structure to load

# Callback {{{2
#_json[callback] - name of a callback function or command

####  Debugging subroutines  ###############################################@{
_json_dbg_token() {
  if (( DEBUG >= 2 )); then
    _json_dbg_token() {
      dbg "[%3u:%3u] %s = '%s'" \
        "${_json_file[line]}"  "${_json_file[char]}" \
        "${_json_token[type]}" "${_json_token[text]}"
    }
    _json_dbg_token "$@"
  else
    _json_dbg_token()  { :; }
  fi
}

# _json_dbg_struct <type> <name> <keys> {{{2
_json_dbg_struct() {
  if (( DEBUG >= 1 )); then
    _json_dbg_struct() {
      local type="$1" name="$2" keys="$3"
      dbg "<%2u> %-6s %s" "$_json_level" "$type" "${name:-JSON}$keys"
    }
    _json_dbg_struct "$@"
  else
    _json_dbg_struct() { :; }
  fi
}

# _json_dbg_value <name> <keys> <type> [value] {{{2
_json_dbg_value() {
  if (( DEBUG >= 1 )); then
    _json_dbg_value() {
      local name="$1" keys="$2" type="$3" value="$4"

      name="${name:-JSON}$keys"

      case $type in
        object|array) value="<$type>"    ;;
        string)       value="\"$value\"" ;;
      esac

      dbg "<%2i> %-6s %s" $_json_level value "$name = $value"
    }
    _json_dbg_value "$@"
  else
    _json_dbg_value()  { :; }
  fi
}

####  Error handlers  ######################################################@{
# _json_throw <code> <msg> [args …] {{{2
_json_throw() {
  local code="$1" msg="$2"; shift 2
  throw -d 2 -c "$code" "$msg" "$@"
}

# _json_dataerr <type> <msg> [args …] {{{2
_json_dataerr() {
  local type="$1" msg="$2"; shift 2
  _json_throw DATAERR "%s: $msg (%s:%i:%i)" "$type" "$@" \
    "${_json_file[name]}" "${_json_file[line]}" "${_json_file[char]}"
}

# _json_expected <string> {{{2
_json_expected() {
  _json_dataerr parser "$(_ "expected %s, got %s")" "$1" "${_json_token[text]}"
}

####  Callback functions  ##################################################@{
# _json_echo <name> <keys> <type> [value] {{{2
_json_echo() {
  local name="$1" keys="$2" type="$3" value="$4"

  [[ -n $name ]] || return 0
  name="$name$keys"

  case $type in
    object|array) echo "$name = <$type>"    ;;
    string)       echo "$name = \"$value\"" ;;
    number|bool)  echo "$name = $value"     ;;
    null)         echo "$name = $type"      ;;
  esac

  return 0
}

####  Lexical analysis  ####################################################@{
_json_get_line() {
  _json_line=''

  if ! IFS='' read -r _json_line && [[ $? -ne 1 && -z $_json_line ]]; then
    return 65 # end of file
  fi

  (( _json_file[line]++, _json_file[char] = 1 )) || :

  return 0
}

_json_get_token() {
  local type

  _json_token[type]='' _json_token[text]=''

  if [[ -z $_json_line ]] && ! _json_get_line; then
    _json_token[type]='EOF' _json_token[text]="$(_ 'end of file')"
    return 0
  fi

  for type in "${!_json_regex[@]}"; do
    if [[ $_json_line =~ ^${_json_regex[$type]} ]]; then
      _json_token[type]="$type"
      _json_token[text]="${BASH_REMATCH[1]}"
      _json_dbg_token

      _json_line="${_json_line:${#BASH_REMATCH[0]}}"
      (( _json_file[char] += ${#BASH_REMATCH[0]} )) || :

      if _json_token_is space; then
        _json_get_token
      fi

      return 0
    fi
  done

  _json_dataerr lexer "$(_ "unexpected character '%c'")" "${_json_line:0:1}"
}

# _json_token_is <type> [text] {{{2
_json_token_is() {
  local type="$1" text="$2"

  if [[ -n $text ]]; then
    [[ ${_json_token[type]} == "$type" && ${_json_token[text]} == "$text" ]]
  else
    [[ ${_json_token[type]} == "$type" ]]
  fi
}

####  Syntactic analysis  ##################################################@{
_json_parse_object() {
  local parsed="$1" name="$2" keys="$3" key

  _json_dbg_struct object "$name" "${keys:-$parsed}"

  _json_get_token
  if _json_token_is term '}'; then
    return 0 # empty object
  fi
  while true; do
    # key - string
    if _json_token_is string; then
      key="${_json_token[text]}"
    else
      _json_expected "$(_ string)"
    fi
    # ':'
    _json_get_token
    if ! _json_token_is term ':'; then
      _json_expected "':'"
    fi
    # value
    _json_parse_value "${parsed}[$key]" "$name" "${name:+${keys}[$key]}"
    (( _json_done )) && return 0 || :
    # separator ',' or bracket '}'
    _json_get_token
    if _json_token_is term '}'; then
      return 0 # end of object
    elif ! _json_token_is term ','; then
      _json_expected "$(_ "',' or '}'")"
    fi
    # next element
    _json_get_token
  done

  return 0
}

_json_parse_array() {
  local parsed="$1" name="$2" keys="$3"
  local -i i=0

  _json_dbg_struct array "$name" "${keys:-$parsed}"

  _json_get_token
  if _json_token_is term ']'; then
    return 0 # empty array
  fi
  while true; do
    # element - value
    _json_parse_value "${parsed}[$i]" "$name" "${name:+${keys}[$i]}" -
    (( _json_done )) && return 0 || :
    # separator ',' or bracket ']'
    _json_get_token
    if _json_token_is term ']'; then
      return 0 # end of array
    elif ! _json_token_is term ','; then
      _json_expected "$(_ "',' or ']'")"
    fi
    # next element
    _json_get_token
    (( i++ )) || :
  done

  return 0
}

_json_parse_struct() {
  local parsed="$1" name="$2" keys="$3" type
  local -i callback=0

  case ${_json_token[text]} in
    '{') type='object' ;;
    '[') type='array'  ;;
  esac

  if [[ $parsed == "${_json_array[keys]}" && ! $name ]]; then
    name="${_json_array[name]}" keys="" callback=1
  fi

  _json_dbg_value "$name" "${keys:-$parsed}" "$type"
  [[ $name ]] && "$_json_callback" "$name" "$keys" "$type" || :

  (( _json[level]++ )) || :
  _json_parse_$type "$parsed" "$name" "$keys"
  (( _json[level]-- )) || :

  (( callback || ! _json[level] )) && _json[done]=1 || :

  return 0
}

_json_parse_value() {
  local parsed="$1" name="$2" keys="$3" type value

  [[ $4 ]] || _json_get_token
  case ${_json_token[type]} in
    term)
      case ${_json_token[text]} in
        '{'|'[') _json_parse_struct "$parsed" "$name" "$keys"; return 0 ;;
        '#')     _json_get_line && _json_parse_value "$parsed" "$name" "$keys"; return 0 ;;
        *)       _json_expected "$(_ value)"
      esac ;;
    keyword)
      case ${_json_token[text]} in
        true|false) type="bool" value="${_json_token[text]}" ;;
        null)       type="null" value=""                     ;;
        *)          _json_expected "$(_ value)"
      esac ;;
    string|number) type="${_json_token[type]}" value="${_json_token[text]}" ;;
    *)             _json_expected "$(_ value)"
  esac

  _json_dbg_value "$name" "${keys:-$parsed}" "$type" "$value"
  [[ $name ]] && "$_json_callback" "$name" "$keys" "$type" "$value" || :

  return 0
}

_json_parse() {
  typeset -gA _json _json_token

  _json_parse_value
  if (( ! _json[done] )); then
    _json_get_token
    if ! _json_token_is EOF; then
      _json_expected "$(_ 'end of file')"
    fi
  fi

  unset _json _json_token

  return 0
}

####  Load JSON data from file or stdin to array  ##########################@{
json_load() {
  typeset -gA _json_array _json_file
  typeset -g  _json_callback
  local rx_keys='^(\[[^]]*\])+$' OPT OPTARG
  local -i OPTIND r

  # Default and initial values
  _json_file[name]='stdin' _json_file[line]=0 _json_file[char]=0
  _json_callback='aset_json'

  eval "$(try)"; while true; do
    # Parse options
    while getopts ':a:k:f:c:' OPT; do
      case $OPT in
        a)
          if [[ $OPTARG == [A-Za-z]*([0-9A-Za-z_]) ]]; then
            _json_array[name]="$OPTARG"
          else
            _json_throw USAGE "$(_ "option '%c': invalid variable name '%s'")" "$OPT" "$OPTARG"
          fi ;;
        k)
          if [[ $OPTARG =~ $rx_keys ]]; then
            _json_array[keys]="${BASH_REMATCH[0]}"
          else
            _json_throw USAGE "$(_ "option '%c': invalid keys specification '%s'")" "$OPT" "$OPTARG"
          fi ;;
        f)
          if [[ -f "$OPTARG" && -r "$OPTARG" ]]; then
            _json_file[name]="$OPTARG"
          elif [[ -f "$OPTARG.json" && -r "$OPTARG.json" ]]; then
            _json_file[name]="$OPTARG.json"
          else
            _json_throw NOINPUT "$(_ "option '%c': cannot read JSON file '%s'")" "$OPT" "$OPTARG"
          fi ;;
        c)
          if type "$OPTARG" &>/dev/null; then
            _json_callback="$OPTARG"
          else
            _json_throw NOCMD "$(_ "option '%c': unknown command '%s'")" "$OPT" "$OPTARG"
          fi ;;
        \?) _json_throw USAGE "$(_ "invalid option '%c'")" "$OPTARG" ;;
        :)  _json_throw USAGE "$(_ "option '%c': missing argument")" "$OPTARG" ;;
      esac
    done
    (( OPTIND > 1 )) && shift $(( OPTIND - 1 )) || :

    if [[ ${_json_file[name]} != 'stdin' ]]; then
      # Open input file for reading: associate with file descriptor 0 (stdin)
      exec < "${_json_file[name]}"
    fi

    # Parse JSON data and set array variable
    _json_parse
  break; done; eval "$(end_try)"; r=$?

  # Unset JSON variables
  unset _json_array _json_file _json_callback

  return $r
}

# vim: set et sw=2 ts=2 fen fdm=marker fmr=@{,@}:
