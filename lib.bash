## @file    $XDG_DATA_HOME/bash/lib.bash
## @brief   Bash scripting library.
## @author  Vasiliy Polyakov
## @date    2016-2019
## @pre     bash>=4.0  (GNU Bourne again shell).
## @pre     coreutils  (@c dirname, @c realpath).
## @pre     doxygen    (for API reference, optional).

####  Source guard  #######################################################@{1
[ x"$BASH_VERSION" = x ] && return 1  # Current shell is not Bash
(( BASH_VERSINFO[0] < 4 )) && return 2  # Bash version is not supported
[[ -n $BASH_LIB ]] && return 0  # Sourced already
type -f realpath dirname &>/dev/null || return 3  # Coreutils are not installed

## @c BASH_LIB contains the path to the Bash library directory.
declare -gr BASH_LIB="$(dirname "$(realpath -qe "${BASH_SOURCE[0]}")")/lib"

####  Private functions  ##################################################@{1
_lib::init() {
  # Set options
  shopt -qs extglob   # enable extended pattern matching
  shopt -qs globstar  # '**' matches all files and zero or more (sub)directories
  shopt -qs xpg_echo  # echo expands backslash-escape sequences by default
  shopt -qs expand_aliases

  # Regular expressions
  # Special characters in regular expressions (@see regex(7)).
  declare -gra _regex_chars=('|' '*' '+' '?' '{' '}' '(' ')' '[' ']' '.' '^' '$' '\')
}

## Convert an array to a regular expression.
## @param   $@  Array values.
## @return  Nothing.
## @stdout  Regular expression for array.
_a2re() {
  local -a r=("$@")
  local c

  # Escape special characters
  for c in "${_re_chars[@]}"; do
    r=("${r[@]//"$c"/\\"$c"}")
  done

  local IFS='|'
  echo "(${r[*]})"
}

####  Exported functions  #################################################@{1
## @name  Function stubs.
## @{
_() { echo "$@"; }
dbg() { :; }
title() { false; }
## @}

## @name  Source guards.
## @{

## Is this script sourced?
## @param   $1  Function call stack frame number (>= 1).
## @return  Boolean value.
## @retval  0  Sourced.
## @retval  1  Not sourced.
is_sourced() {
  local -i frame="${1:-1}"
  [[ ${FUNCNAME[frame]} == 'source' ]]
}

## Is this script imported?
## @param   $1  Function call stack frame number (>= 1).
## @return  Boolean value.
## @retval  0  Imported.
## @retval  1  Not imported.
is_imported() {
  local -i frame="${1:-1}"
  [[ ${FUNCNAME[frame]} == 'source' && ${FUNCNAME[frame+1]} == 'import' ]]
}

## Import a library file only once.
## @detail Use `import_once || return $?`
##         at the beginning of the Bash library file (@c lib/*.sh).
## @return Import error.
## @retval  64 this library was not imported.
## @retval  69 Bash lib was not initialized correctly.
## @retval 127 import_once: command not found (retured by Bash).
import_once() {
  [ x"$BASH_LIB" = x ] && return 69  # UNAVAILABLE

  local name="$(relpath "${BASH_SOURCE[1]}" "$BASH_LIB")"
  name="${name%.*}"; name="_BASH_${name^^}_"

  eval "(( $name ))" && return 0  # Imported already
  is_imported 2 || return 64  # USAGE

  local -i version="${1:-1}"
  eval "declare -gri $name='$version'"

  return 0
}
## @}

## @name  Source libraries.
## @{

## Import Bash library.
## @param   $1  Library name.
## @param   $@  Additional parameters for the library.
## @return  Nothing.
## @throw   USAGE    Missing library name.
## @throw   NOINPUT  Library file not found.
## @throw   NOINPUT  Cannot read library file.
import() {
  [[ -n $1 ]] || throw -c USAGE "$(_ 'arg 1: missing library name')"
  local lib="$1"; shift

  # Relative path specified as the first positional argument
  [[ ${lib:0:1} != '/' ]] && lib="$BASH_LIB/$lib"
  # Try to add a filename suffix
  [[ ! -f "$lib" && -f "${lib}.sh" ]] && lib+='.sh'

  [[ -f $lib ]] || throw -c NOINPUT "$(_ "no such file: '%s'")" "$lib"
  [[ -r $lib ]] || throw -c NOINPUT "$(_ "cannot read file: '%s'")" "$lib"

  source "$lib" "$@"
}
## @}

## Check if @c needle is in a @c haystack array.
## @param   $1  Haystack (name of array variable).
## @param   $2  Needle (value to find).
## @return  Boolean result.
## @retval   0  Found.
## @retval   1  Not found.
## @throw   USAGE  Missing array name.
## @throw   USAGE  Missing value to find.
in_array() {
  [[ -n $1 ]] || throw -c USAGE "$(_ 'arg 1: missing array name')"
  [[ -n $2 ]] || throw -c USAGE "$(_ 'arg 2: missing value to find')"

  local -n haystack="$1"
  local needle="$2" hay

  for hay in "${haystack[@]}"; do
    [[ "$hay" == "$needle" ]] && return 0
  done

  return 1
}

## @brief   Output path to @c file relative to specified or current directory.
## @param   $1  Filename.
## @param   $2  Directory name [$PWD].
## @return  Nothing.
## @stdout  Relative path.
relpath() {
  realpath --quiet --relative-base="${2:-$PWD}" "$1"
}

_lib::init
import exceptions

# vim: set et sw=2 ts=2 fen fdm=marker fmr=@{,@}:
