## @file    $XDG_DATA_HOME/bash/lib.bash
## @brief   Bash scripting library.
## @author  Vasiliy Polyakov
## @date    2016-2019
## @pre     bash>=4.0  (GNU Bourne again shell).
## @pre     coreutils  (@c dirname, @c realpath).
## @pre     doxygen    (for API reference, optional).

####  Source guard  #######################################################@{1
[ x"$BASH_VERSION" = x ] && return 1  # Current shell is not Bash
[[ -n $BASH_LIB ]] && return 0  # Sourced already
(( BASH_VERSINFO[0] < 4 )) && return 2  # Bash version is not supported
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

## @brief   Is this script sourced?
## @param   $1  Function call stack frame number (>= 1).
## @return  Boolean value.
## @retval  0  Sourced.
## @retval  1  Not sourced.
is_sourced() {
  local -i frame="${1:-1}"
  [[ ${FUNCNAME[frame]} == 'source' ]]
}

## @brief   Is this script imported?
## @param   $1  Function call stack frame number (>= 1).
## @return  Boolean value.
## @retval  0  Imported.
## @retval  1  Not imported.
is_imported() {
  local -i frame="${1:-1}"
  [[ ${FUNCNAME[frame]} == 'source' && ${FUNCNAME[frame+1]} == 'import' ]]
}

## @brief   Import a library file only once.
## @detail  Use `import_once || return $(($?-1))`
##          at the beginning of the Bash library file (@c lib/*.sh).
## @return  Import error.
## @retval    0  OK.
## @retval    1  Library has been imported already.
## @retval    2  Bash lib was not initialized correctly.
## @retval    3  This library was not imported correctly.
## @retval  127  import_once: command not found (retured by Bash).
import_once() {
  [ x"$BASH_LIB" = x ] && return 2

  local name="$(relpath "${BASH_SOURCE[1]}" "$BASH_LIB")"
  name="${name%.*}"; name="_BASH_${name^^}_"

  eval "(($name))" && return 1
  is_imported 2 || return 3

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
## @return  Error code.
## @retval   0  OK.
## @retval   1  Missing library name (arg 1).
## @retval   2  Cannot read library file.
import() {
  [[ -n $1 ]] || return 1
  local lib="$1"; shift

  # Add lib dir if path is relative
  [[ ${lib:0:1} != '/' ]] && lib="$BASH_LIB/$lib"
  # Try to add a filename suffix
  [[ ! -f "$lib" ]] && lib+='.sh'

  [[ -r $lib ]] || return 2

  source "$lib" "$@"
}
## @}

## Convert array to a regular expression.
## @param   $@  Array values.
## @return  Nothing.
## @stdout  Regular expression for array.
a2re() {
  local -a r=("$@") s=('|' '*' '+' '?' '{' '}' '(' ')' '[' ']' '.' '^' '$' '\')
  local c

  # Escape special characters
  for c in "${s[@]}"; do
    r=("${r[@]//"$c"/\\"$c"}")
  done

  local IFS='|'
  echo "(${r[*]})"
}

## Check if @c needle is in a @c haystack array.
## @param   $1  Haystack (name of array variable).
## @param   $2  Needle (value to find).
## @return  Boolean result.
## @retval   0  Found.
## @retval   1  Not found.
## @retval  -1  Missing arguments.
in_array() {
  [[ -n $1 && -n $2 ]] || return -1

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

# vim: set et sw=2 ts=2 fen fdm=marker fmr=@{,@}:
