#!/bin/bash
# vim: set ft=sh et sw=2 ts=2:

echo "$(dirname "$(realpath --quiet --canonicalize-existing "${BASH_SOURCE[0]}")")"
exit 0

. ./lib.sh
#use term/title

in_array() {
  [[ ! $1 || ! $2 ]] && return 64

  local -n haystack="$1"
  local needle="$2" hay

  for hay in "${haystack[@]}"; do
    [[ "$hay" == "$needle" ]] && return 0
  done

  return 1
}

in_array2() {
  local -n haystack="$1"
  local needle="$2" hay

  echo "${haystack[@]/#$needle}"
}

declare -a a1=(a 'b?f' c d)
#in_array a1 a && echo true || echo false
#in_array2 a1 b

#declare -F

#title "t'e's't" $'\x31'

_a2re "${a1[@]}"
