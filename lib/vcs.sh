## @file    $XDG_DATA_HOME/bash/lib/vcs.sh
## @brief   Bash functions for VCS.
## @author  Vasiliy Polyakov
## @date    2019
## @pre     lib.bash   (Bash scripting library).
## @pre     colors.sh  (Color terminal support).
## @pre     git.sh     (Git VCS).

import_once || return $?
import colors
import git

declare -gA VCS_CHAR=(
  [changed]='*'
  [staged]='⊛'
  [ahead]='↑'
  [behind]='↓'
  [progress]='!'
)

vcs::prompt() {
  if git::in_work_tree; then
    local branch="$(_git::branch)"
    local progress="$(_git::progress)"

    local status="\[${FG[13]}\]$branch\[${SGR0}\]"
    git::is_changed && status+="\[${FG[11]}\]${VCS_CHAR[changed]}\[${SGR0}\]"
    git::is_staged  && status+="\[${FG[10]}\]${VCS_CHAR[staged]}\[${SGR0}\]"
    [[ -n $progress ]] && status+="\[${FG[9]}\]${VCS_CHAR[progress]}${progress}\[${SGR0}\]"

    echo "[$status]"
  fi
}
