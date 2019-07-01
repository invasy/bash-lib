set_font() {
  local -i s=710 bold=0 italic=0 size=12 OPTIND
  local antialias=False hinting=True style font o OPTARG

  while getopts 'bis:S:aAhH' o; do
    case $o in
      b) bold=1 ;;
      i) italic=1 ;;
      s) size="$OPTARG" ;;
      S) style="$OPTARG" ;;
      a) antialias=True ;;
      A) antialias=False ;;
      h) hinting=True ;;
      H) hinting=False ;;
    esac
  done
  (( OPTIND > 1 )) && shift $(( OPTIND - 1 ))

  font="${1:?must be a font name}"
  s+='bold | italic << 1'
  if [[ -z $style ]]; then
    if (( bold && !italic )); then
      style='Bold'
    elif (( !bold && italic )); then
      style='Italic'
    elif (( bold && italic )); then
      style='Bold Italic'
    else
      style='Regular'
    fi
  fi

  printf '\e]%d;%s\a' "$s" "xft:$font:style=$style:pixelsize=$size:antialias=$antialias:hinting=$hinting"
}

_echo_nums() {
  local -i w="${1:?width}" i
  echo -n "     "
  for (( i = 0; i < w; i++ )); do
    printf ' %X' "$(( i % 16 ))"
  done
  echo
}

echo_chars() {
  local -i first=32 last=127 width=32 header=1 footer=1 fg=-1 bg=-1 c OPTIND
  local sgr sgr0 h o OPTARG

  while getopts 'a:z:n:oxwqW:HFNf:b:' o; do
    case $o in
      a) first="16#$OPTARG" ;;
      z) last="16#$OPTARG"  ;;
      n) last="first+$OPTARG-1" ;;
      o) width=8  ;;
      x) width=16 ;;
      w) width=32 ;;
      q) width=64 ;;
      W) width="$OPTARG" ;;
      H) header=0 ;;
      F) footer=0 ;;
      N) header=0 footer=0 ;;
      f) fg="$OPTARG" ;;
      b) bg="$OPTARG" ;;
    esac
  done
  (( OPTIND > 1 )) && shift $(( OPTIND - 1 ))

  (( fg != -1 )) && sgr+="38;5;$fg;"
  (( bg != -1 )) && sgr+="48;5;$bg"
  [[ $sgr ]] && sgr="\e[${sgr%;}m" sgr0="\e[m"

  (( header )) && _echo_nums "$width"; o=''
  for (( c = first/width*width; c <= last; c++ )); do
    if (( c % width == 0 )); then
      printf -v h "%04X:" "$c" && o+="$h$sgr"
    fi
    if (( c >= first )); then
      printf -v h ' \\u%04X' "$c" && o+="$h"
    else
      o+='  '
    fi
    if (( c % width == width - 1 || c == last )); then
      o+="$sgr0\n"
    fi
  done
  echo -ne "$o"
  (( footer )) && _echo_nums "$width"
}

echo_test_chars() {
  echo '0123456789ABCDEF ,.?!@#$%^&*+-=_~'
  echo 'oO0 il1' "\`'" '()[]{}<>\|/'
  echo 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  echo 'abcdefghijklmnopqrstuvwxyz'
  echo 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ'
  echo 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя'
  echo
  echo 'Seti-UI'
  echo_chars -N -a 'e4f0' -z 'e52b'
  echo 'Devicons'
  echo_chars -N -a 'e700' -n 64
  echo 'Font Awesome'
  echo_chars -N -a 'f000' -n 64
  echo 'Octicons'
  echo_chars -N -a 'f400' -n 64
  echo 'Powerline'
  echo_chars -N -a 'e0a0' -z 'e0d4'
  echo 'Font Linux'
  echo_chars -N -a 'f100' -z 'f115'
  echo
}

# vim: set ft=sh et sw=2 ts=2:
