## @file    $XDG_DATA_HOME/bash/lib/git.sh
## @brief   Bash functions for Git.
## @author  Vasiliy Polyakov
## @date    2019
## @pre     lib.bash  (Bash scripting library).
## @pre     Git       (Git VCS).

import_once || return $?

_git::in_work_tree() {
  local inside="$(git rev-parse --is-inside-work-tree 2>/dev/null)"
  [[ $inside == 'true' ]]
}

_git::in_git_dir() {
  local inside="$(git rev-parse --is-inside-git-dir 2>/dev/null)"
  [[ $inside == 'true' ]]

}

_git::dir() {
  git rev-parse --git-dir 2>/dev/null
}

_git::branch() {
  git rev-parse --abbrev-ref --symbolic-full-name @
}

_git::remote() {
  git rev-parse --abbrev-ref --symbolic-full-name @{upstream}
}

_git::is_changed() {
  git diff --quiet
}

_git::is_staged() {
  git diff --cached --quiet
}

_git::changed_num() {
  git diff --numstat | wc --lines
}

_git::staged_num() {
  git diff --cached --numstat | wc --lines
}

_git::ahead_num() {
  git log --no-decorate --no-merges --oneline @{upstream}..@ | wc --lines
}

_git::behind_num() {
  git log --no-decorate --no-merges --oneline @..@{upstream} | wc --lines
}

_git::progress() {
  local dir="$(_git::dir)" in

  if [[ -f "$dir/MERGE_HEAD" ]]; then
    in="$(_ MERGE)"
  elif [[ -d "$dir/rebase-apply" ]]; then
    if [[ -f "$dir/rebase-apply/applying" ]]; then
      in="$(_ AM)"
    else
      in="$(_ REBASE)"
    fi
  elif [[ -d "$dir/rebase-merge" ]]; then
    in="$(_ REBASE)"
  elif [[ -f "$dir/CHERRY_PICK_HEAD" ]]; then
    in="$(_ CHERRY)"
  fi
  if [[ -f "$dir/BISECT_LOG" ]]; then
    [[ -n $in ]] && in+='+'
    in+="$(_ BISECT)"
  fi
  if [[ -f "$dir/REVERT_HEAD" ]]; then
    [[ -n $in ]] && in+='+'
    in+="$(_ REVERT)"
  fi

  [[ -n $in ]] && echo "$in"
}
