#!/usr/bin/env bats

setup() {
  . lib.sh
}

@test "_a2re: one element" {
  local -a a=(a b c)
  result="$(_a2re "${a[@]}")"
  [ $result == '(a|b|c)']
}
