## # Color terminal support
##
## Copyright © 2016-2022 [Vasiliy Polyakov](mailto:bash@invasy.dev).
##
## ## Prerequisites
## - `lib.bash` - Bash scripting library;
## - `ncurses` — `tput`.
##
# TODO: add documentation

bash_lib || return $(($?-1))

if ! type -p tput &>/dev/null || [[ $1 == '0' ]]; then
  declare -gir COLORS=0
  declare -gr SGR0=''
  SGR() { :; }
  return 0
fi

# shellcheck disable=SC2155
declare -gir COLORS="$(tput colors)"
# shellcheck disable=SC2034
declare -gr  SGR0=$'\e[m'

_colors::to_attr() {
  local OPT OPTARG
  local -i OPTIND=1 OPTERR=0 color bg=0

  while getopts ':bf' OPT; do
    case $OPT in
      f) bg=0 ;;
      b) bg=10 ;;
      *) continue
    esac
  done; shift $((OPTIND - 1))

  color="$1"

  if ((color < 8 && color >= 0)); then
    echo $((color + 30 + bg))
  elif ((color < 16)); then
    echo $((color + 82 + bg))
  elif ((color < 256)); then
    echo $((38 + bg)) 5 "$color"
  fi
}

SGR() {
  local OPT OPTARG E='-e' P0='' P1='' a
  local -i OPTIND=1 OPTERR=0
  local -a A C C8 C16 C256

  while getopts ':Ep' OPT; do
    case $OPT in
      E) E='' ;;
      p) P0='\[' P1='\]' ;;
      *) continue
    esac
  done; shift $((OPTIND - 1))

  for a; do
    # shellcheck disable=SC2207
    case $a in
      fg=+([0-9])) C+=($(_colors::to_attr -f "${a#*=}")) ;;
      bg=+([0-9])) C+=($(_colors::to_attr -b "${a#*=}")) ;;
      fg8=+([0-9])) C8+=($(_colors::to_attr -f "${a#*=}")) ;;
      bg8=+([0-9])) C8+=($(_colors::to_attr -b "${a#*=}")) ;;
      fg16=+([0-9])) C16+=($(_colors::to_attr -f "${a#*=}")) ;;
      bg16=+([0-9])) C16+=($(_colors::to_attr -b "${a#*=}")) ;;
      fg256=+([0-9])) C256+=($(_colors::to_attr -f "${a#*=}")) ;;
      bg256=+([0-9])) C256+=($(_colors::to_attr -b "${a#*=}")) ;;
      @(f|b)g=black) C+=($(_colors::to_attr "-${a%%g=*}" 0)) ;;
      @(f|b)g=red) C+=($(_colors::to_attr "-${a%%g=*}" 1)) ;;
      @(f|b)g=green) C+=($(_colors::to_attr "-${a%%g=*}" 2)) ;;
      @(f|b)g=yellow) C+=($(_colors::to_attr "-${a%%g=*}" 3)) ;;
      @(f|b)g=blue) C+=($(_colors::to_attr "-${a%%g=*}" 4)) ;;
      @(f|b)g=magenta) C+=($(_colors::to_attr "-${a%%g=*}" 5)) ;;
      @(f|b)g=cyan) C+=($(_colors::to_attr "-${a%%g=*}" 6)) ;;
      @(f|b)g=white) C+=($(_colors::to_attr "-${a%%g=*}" 7)) ;;
      fg=@(default|def|d)) A+=(39) ;;
      bg=@(default|def|d)) A+=(49) ;;
      reset | r | x | X) A+=(0) ;;
      bold | b | \*) A+=(1) ;;
      dim) A+=(2) ;;
      italics | ital | i | /) A+=(3) ;;
      underline | underscore | uline | ul | u | _) A+=(4) ;;
      blink) A+=(5) ;;
      reverse | rev | inverse | inv) A+=(7) ;;
      normal | n | -) A+=(22) ;;
      +([0-9])) A+=("$a") ;;
    esac
  done

  local -n c="C$COLORS"
  if ((${#c[@]})); then
    A+=("${c[@]}")
  else
    A+=("${C[@]}")
  fi

  if ((${#A[@]})); then
    local IFS=';'
    # shellcheck disable=SC2086
    echo -n $E "$P0\e[${A[*]}m$P1"
  fi
}

# vim: set et sw=2 ts=2 fdm=marker fmr=@{,@}:
