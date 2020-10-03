## @file    $XDG_DATA_HOME/bash/lib/git.sh
## @brief   Bash functions for Git.
## @author  Vasiliy Polyakov
## @date    2019-2020
## @pre     lib.bash  (Bash scripting library).
## @pre     Git       (Git VCS).

bash_lib || return $(($?-1))

git::in_work_tree() {
  local inside="$(git rev-parse --is-inside-work-tree 2>/dev/null)"
  [[ $inside == 'true' ]]
}

git::in_git_dir() {
  local inside="$(git rev-parse --is-inside-git-dir 2>/dev/null)"
  [[ $inside == 'true' ]]
}

git::dir() {
  git rev-parse --git-dir 2>/dev/null
}

git::branch() {
  local branch="$(git rev-parse --abbrev-ref --symbolic-full-name @ 2>/dev/null)"
  [[ $branch == '@' ]] && echo "$(_ "<no commits>")" || echo "$branch"
}

git::remote() {
  git rev-parse --abbrev-ref --symbolic-full-name @{upstream}
}

git::is_changed() {
  ! git diff --quiet
}

git::is_staged() {
  ! git diff --cached --quiet
}

git::changed() {
  git diff --numstat | wc --lines
}

git::staged() {
  git diff --cached --numstat | wc --lines
}

git::ahead() {
  git log --no-decorate --no-merges --oneline @{upstream}..@ | wc --lines
}

git::behind() {
  git log --no-decorate --no-merges --oneline @..@{upstream} | wc --lines
}

git::action() {
  local dir="$(git::dir)" in

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

