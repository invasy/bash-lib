## #  bash-lib  ##########################################################@{1
## `$XDG_DATA_HOME/bash/lib.bash` — Bash scripting library.
##
## Copyright © 2016-2022 [Vasiliy Polyakov](mailto:bash@invasy.dev).
##
## ## Prerequisites
## - [Bash](https://www.gnu.org/software/bash/) — GNU Bourne again shell, version >= 4.0.
## - `coreutils` package — `dirname`, `realpath`.
##
## ##  Source Guard  #####################################################@{2
## When sourced **bash-lib** returns these codes on error:
## - `1` — current shell is not Bash;
## - `2` — Bash version is not supported;
## - `3` — package `coreutils` is not installed.

[ x"$BASH_VERSION" != x ] || return 1             # current shell is not Bash
[[ -z $BASH_LIB || $1 == '-f' ]] || return 0      # library is sourced already
(( BASH_VERSINFO[0] >= 4 )) || return 2           # Bash version is not supported
type -p dirname realpath &>/dev/null || return 3  # package `coreutils` is not installed

# shellcheck disable=SC2155
declare -gr BASH_LIB="$(realpath -qe "$(dirname "${BASH_SOURCE[0]}")/lib")"
##
## ##  XDG Base Directories  #############################################@{2
## **bash-lib** supports [XDG Base Directories Specification][xdg].
if [[ -z $XDG_CONFIG_HOME ]]; then
  export XDG_CONFIG_HOME="$HOME/.config"
fi
if [[ -z $XDG_DATA_HOME ]]; then
  export XDG_DATA_HOME="$HOME/.local/share"
fi
if [[ -z $XDG_CACHE_HOME ]]; then
  export XDG_CACHE_HOME="$HOME/.cache"
fi
##
## ---
##
## ##  Variables  ########################################################@{2
## - `$BASH_LIB` — path to the **bash-lib** directory.
##
_lib::init() {
  ## ##  Options  ########################################################@{2
  ## ### General Options
  shopt -s lastpipe  ## execute the last cmd of a pipeline in current shell;
  shopt -s xpg_echo  ## `echo` expands escape sequences.

  ## ### Globbing
  shopt -s globstar  ## `**` recurses through subdirectories;
  shopt -s extglob   ## enable extended pattern matching;
  shopt -u failglob  ## failed patterns do not result in an error;
  shopt -s nullglob  ## patterns that match no files are expand to empty string.
}
##
## ---
##
## ##  Functions  ########################################################@{2
##
## ### bash_lib
## Library header.
## #### Usage
## ```bash
## bash_lib [-n name] [-v version] [-x] || return $(($?-1))
## ```
## _at the beginning of the library file (`lib/*.sh`)_
## #### Options
## - `-n name` — library name (default: determine from filename);
## - `-v version` — library version (default: `1.0.0`);
## - `-x` — library is not implemented yet.
## #### Returns
## - `0` — OK;
## - `1` — library was already imported (_not an error_);
## - `127` — `bash_lib: command not found` (_error code from Bash_);
## - `250` — library was not implemented yet;
## - `252` — invalid library file path;
## - `253` — this library was not imported properly;
## - `254` — **bash-lib** was not initialized properly.
##
bash_lib() {
  [ x"$BASH_LIB" != x ] || return 254

  local name version='1.0.0'
  local OPT OPTARG
  local -i OPTIND=1 OPTERR=0

  while getopts :n:v:x OPT; do
    case $OPT in
    n) name=$OPTARG ;;
    v) version=$OPTARG ;;
    x) return "${BASH_ERROR[NOTIMPL]}" ;;
    *) continue ;;
    esac
  done

  if [[ -z $name ]]; then
    # Set library name from filename
    name="$(relpath "${BASH_SOURCE[1]}" "$BASH_LIB")"
    if [[ ${name:0:1} == '/' ]]; then
      return "${BASH_ERROR[INVPATH]}"
    fi
    name="${name%.*}"
  fi
  # Set guard variable name
  local var="__BASH_${name^^}__"

  eval "semvercmp \"\$${var}\" '${version}'"
  if (($? < 2)); then
    return 1
  fi

  if ! is_imported 2; then
    return "${BASH_ERROR[IMPORT]}"
  fi

  # Set source guard variable to library version
  eval "declare -gr ${var}='${version}'"
}

## ### import
## Imports Bash library.
## #### Usage
## ```bash
## import library [args …]
## ```
## #### Arguments
## - `$1` — library name;
## - `$@` — additional parameters for the library.
## #### Returns
## - `0` — OK;
## - `1` — missing library name (arg 1);
## - `251` — cannot read library file;
## - `254` — `bash-lib` was not initialized correctly.
##
import() {
  [ x"$BASH_LIB" != x ] || return 254

  local lib=${1:?${FUNCNAME[0]}: missing library name}; shift

  # Add lib dir if path is relative
  if [[ ${lib:0:1} != '/' ]]; then
    lib="$BASH_LIB/$lib"
  fi
  # Try to add a filename suffix
  if [[ ! -f $lib ]]; then
    lib+='.sh'
  fi
  # Library file is not found or cannot be read
  if [[ ! -r $lib ]]; then
    return "${BASH_ERROR[READLIB]}"
  fi

  # shellcheck source=/dev/null
  source "$lib" "$@"
}

## ### is_sourced
## Is this script sourced?
## #### Usage
## ```bash
## is_sourced [frame]
## ```
## #### Arguments
## - `$1` - function call stack frame number (⩾1, default: `1`).
## #### Returns
## - `0` — sourced;
## - `1` — not sourced.
##
is_sourced() {
  local -i frame=${1:-1}
  [[ ${FUNCNAME[frame]} == 'source' ]]
}

## ### is_imported
## Is this script/library imported?
## #### Usage
## ```bash
## is_imported [frame]
## ```
## #### Arguments
## - `$1` — function call stack frame number (⩾1, default: `1`).
## #### Returns
## - `0` — imported;
## - `1` — not imported.
##
is_imported() {
  local -i frame=${1:-1}
  [[ ${FUNCNAME[frame]} == 'source' && ${FUNCNAME[frame + 1]} == 'import' ]]
}

## ### semver
## Parses semantic version string.
## #### Usage
## ```bash
## semver version
## ```
## #### Arguments
## - `$1` — version string.
## #### Returns
## - `0` — OK;
## - `1` — cannot parse version string.
## #### Stdout
## ```
## major minor patch
## [pre-release …]
## [build …]
## ```
## #### See Also
## - [Semantic Versioning][semver].
##
# shellcheck disable=SC2086
semver() {
  local -r semver='^([0-9]+)\.([0-9]+)\.([0-9]+)(-([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?(\+([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$'
  if [[ $1 =~ $semver ]]; then
    echo ${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]}
    echo ${BASH_REMATCH[5]//./ }
    echo ${BASH_REMATCH[8]//./ }
  else
    return 1
  fi
}

## ### semvercmp
## Compares two semantic version strings.
## #### Usage
## ```bash
## semvercmp version1 version2
## ```
## #### Arguments
## - `$1` — the first version string;
## - `$2` — the second version string.
## #### Returns
## - `0` — both version strings have equal precedence;
## - `1` — the first version string has higher precedence;
## - `2` — the second version string has higher precedence;
## - `254` — cannot parse the second version string;
## - `255` — cannot parse the first version string.
## #### See Also
## - [Semantic Versioning][semver].
##
# shellcheck disable=SC2181
semvercmp() {
  local -r semver='^([0-9]+)\.([0-9]+)\.([0-9]+)(-([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?(\+([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$'
  local version1=$1 version2=$2
  local -i major1 minor1 patch1 major2 minor2 patch2
  local -a pre1 pre2

  version1="$(semver "$version1")" && {
    read -r major1 minor1 patch1
    read -ra pre1 || :
  } <<< "$version1" || return 255

  version2="$(semver "$version2")" && {
    read -r major2 minor2 patch2
    read -ra pre2 || :
  } <<< "$version2" || return 254

  if ((major1 != major2)); then
    return $(((major1 < major2) + 1))
  elif ((minor1 != minor2)); then
    return $(((minor1 < minor2) + 1))
  elif ((patch1 != patch2)); then
    return $(((patch1 < patch2) + 1))
  elif ((${#pre1[@]} != ${#pre2[@]})); then
    if ((${#pre1[@]} == 0)); then
      return 1
    elif ((${#pre2[@]} == 0)); then
      return 2
    else
      return $(((${#pre1[@]} < ${#pre2[@]}) + 1))
    fi
  elif ((${#pre1[@]} > 0)); then
    local -i i
    for ((i = 0; i < ${#pre1[@]}; i++)); do
      if [[ ${pre1[i]} =~ ^[0-9]+$ && ${pre2[i]} =~ ^[0-9]+$ ]]; then
        if ((pre1[i] != pre2[i])); then
          return $(((pre1[i] < pre2[i]) + 1))
        fi
      else
        if [[ "${pre1[i]}" != "${pre2[i]}" ]]; then
          [[ "${pre1[i]}" > "${pre2[i]}" ]]
          return $(($? + 1))
        fi
      fi
    done
    return 0
  else
    return 0
  fi
}

## ### die
## Prints error message and exit with error code.
## #### Usage
## ```bash
## die [-n name] [-c code] format [arguments …]
## ```
## #### Options
## - `-n name` — script name (default: determine from filename);
## - `-c code` — exit code (default: `1`).
## #### Arguments
## - `$1` — format string;
## - `$@` — message arguments.
## #### Stdout
## Formatted error message.
##
die() {
  local name=${BASH_SOURCE[1]##*/} fmt OPT OPTARG
  local -i code=1 OPTIND=1 OPTERR=0

  while getopts ':c:n:' OPT; do
    case $OPT in
      c) code=$OPTARG ;;
      n) name=$OPTARG ;;
      *) continue
    esac
  done; shift $(( OPTIND - 1 ))

  if [[ $1 == +([0-9]) ]]; then
    code=$1; shift
  fi

  fmt=$1; shift
  # shellcheck disable=SC2059
  printf "$name: error: $fmt\n" "$@" >&2

  exit "$code"
}

## ### a2re
## Converts an array to a regular expression matching array values.
## #### Usage
## ```bash
## a2re value …
## ```
## #### Arguments
## - `$@` — array values.
## #### Stdout
## Regular expression for the array.
##
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

## ### in_array
## Checks if a `needle` is in a `haystack` array.
## #### Usage
## ```bash
## in_array array value
## ```
## #### Arguments
## - `$1` — `haystack` — name of array variable;
## - `$2` — `needle` — value to find.
## #### Returns
## - `0` — found;
## - `1` — not found;
## - `254` — missing argument 2;
## - `255` — missing argument 1.
##
in_array() {
  [[ $1 ]] || return 255
  [[ $2 ]] || return 254

  local -n haystack=$1
  local needle=$2 hay

  for hay in "${haystack[@]}"; do
    if [[ "$hay" == "$needle" ]]; then
      return 0
    fi
  done

  return 1
}

## ### `relpath`
## Prints file path relative to a specified or current directory.
## #### Usage
## ```bash
## relpath filename base
## ```
## #### Arguments
## - `$1` — filename;
## - `$2` — directory name (default: `$PWD`).
## #### Returns
## - `$?` — exit code from `realpath`.
## #### Stdout
## Relative path.
##
relpath() {
  realpath --quiet --relative-base="${2:-$PWD}" "$1"
}

# Function stubs  ########################################################@{2
_() { echo "$@"; }
dbg() { return 0; }
title() { return 1; }

#  Initialization  #######################################################@{2
_lib::init
import sysexits

## ---
##
## ## Libraries
## @LIBS@
## ---
##
## ##  See Also  #########################################################@{2
## - [GNU Bash Manual](https://www.gnu.org/software/bash/manual/)
## - [Advanced Bash-Scripting Guide][absg]
## - [Bash Hackers Wiki](https://wiki.bash-hackers.org/start)
## - [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
##
## [absg]: https://tldp.org/LDP/abs/html/ "Advanced Bash-Scripting Guide"
## [xdg]: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html "XDG Base Directories Specification"
## [semver]: https://semver.org/ "Semantic Versioning"

# vim: set et sw=2 ts=2 fdm=marker fmr=@{,@}:
