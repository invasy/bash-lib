## @file    $XDG_DATA_HOME/bash/lib.bash
## @brief   Bash scripting library.
## @author  Vasiliy Polyakov
## @date    2016-2020
## @pre     bash>=4.0  (GNU Bourne again shell).
## @pre     coreutils  (@c dirname, @c realpath).
## @pre     doxygen    (for API reference, optional).

####  Source guard  #######################################################@{1
[ x"$BASH_VERSION" = x ] && return 1              # Current shell is not Bash
[[ -n $BASH_LIB ]] && return 0                    # Library was already sourced
(( BASH_VERSINFO[0] < 4 )) && return 2            # Bash version is not supported
type -p dirname realpath &>/dev/null || return 3  # Coreutils are not installed

# shellcheck disable=SC2155
## @c BASH_LIB contains the path to the Bash library directory.
declare -gr BASH_LIB="$(realpath -qe "$(dirname "${BASH_SOURCE[0]}")/lib")"

####  Library initialization  #############################################@{1
_lib::init() {
  # Set options
  shopt -qs extglob   # enable extended pattern matching
  shopt -qs globstar  # '**' matches all files and zero or more (sub)directories
  shopt -qs xpg_echo  # echo expands backslash-escape sequences by default
  shopt -qs expand_aliases
}

####  Exported functions  #################################################@{1

## @brief   Bash library header.
## @detail  Use `bash_lib || return $(($?-1))`
##          at the beginning of the Bash library file (@c lib/*.sh).
## @return  Import error.
## @retval    0  OK.
## @retval    1  Library was already imported.
## @retval  125  This library was not imported correctly.
## @retval  126  Bash lib was not initialized correctly.
## @retval  127  'bash_lib: command not found' (returned by Bash itself).
bash_lib() {
  [ x"$BASH_LIB" = x ] && return 126

  local name="$1"
  local -i version="${2:-1}"

  if [[ -z $name ]]; then
    name="$(relpath "${BASH_SOURCE[1]}" "$BASH_LIB")"
    name="${name%.*}"
  fi
  name="__BASH_${name^^}__"

  eval "(($name))" && return 1
  is_imported 2 || return 125

  eval "declare -gri $name='$version'"
}

## @brief   Import Bash library.
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

  [[ -r "$lib" ]] || return 2

  # shellcheck source=/dev/null
  source "$lib" "$@"
}

## @name  Function stubs.
## @{
_() { echo "$@"; }
dbg() { :; }
title() { false; }
## @}

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

## Convert array to a regular expression.
## @param   $@  Array values.
## @return  Nothing.
## @stdout  Regular expression for array.
a2re() {
  # shellcheck disable=SC1003
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
  [[ -n $1 && -n $2 ]] || return 255

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
