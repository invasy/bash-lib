#!/bin/bash
# vim: set ft=sh et sw=2 ts=2:

dir="$(dirname "$(realpath -qe "${BASH_SOURCE[0]}")")"

. "$dir/../lib.bash"
import vcs
time vcs::prompt
time vcs::prompt
