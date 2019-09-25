## @file    $XDG_DATA_HOME/bash/lib/prompt.sh
## @brief   Bash functions for pretty prompt.
## @author  Vasiliy Polyakov
## @date    2019
## @pre     lib.bash  (Bash scripting library).
## @see https://wiki.archlinux.org/index.php/Bash/Prompt_customization
## @see https://github.com/nojhan/liquidprompt
## @see https://www.askapache.com/linux/bash-power-prompt/
## @see https://gitweb.gentoo.org/repo/gentoo.git/tree/app-shells/bash/files/bashrc

import_once || return $?
import color
import git

declare -gA PROMPT_COLOR PROMPT_CHAR

PROMPT_COLOR[user]=10
PROMPT_COLOR[root]=9
PROMPT_COLOR[host]='6 6 36'
PROMPT_COLOR[branch]='5 13 207'
PROMPT_COLOR[changed]=3
PROMPT_COLOR[staged]=11
PROMPT_COLOR[action]=9
PROMPT_COLOR[venv]='3 3 190'

PROMPT_CHAR[user]='>'
PROMPT_CHAR[root]='#'
PROMPT_CHAR[at]='@'
PROMPT_CHAR[git]='±'
PROMPT_CHAR[hg]='☿'
PROMPT_CHAR[svn]='‡'
PROMPT_CHAR[fossil]='⌘'
PROMPT_CHAR[changed]='*'
PROMPT_CHAR[staged]='⊛'
PROMPT_CHAR[stashed]='+'

prompt::init() {
  declare -g PROMPT_COMMAND='prompt::cmd'
  
  for k in "${!PROMPT_COLOR[@]}"; do
    local -a c=(${PROMPT_COLOR[$k]})
    PROMPT_COLOR[$k]="$(tput setaf "${c[${#c[@]}==1||COLORS==8?0:COLORS==16?1:2]}")"
  done
  
  prompt='\[\e[1;38;5;$((EUID?10:9))m\]\u\[\e[m\]@\[\e[1;38;5;36m\]\h\[\e[m\]:\[\e[1;38;5;12m\]\w\[\e[m\]'
  char='\[\e[1;38;5;$((EUID?10:9))m\]$(prompt::char)\[\e[m\]'
  if [[ -n $MC_SID ]]; then  # Bash is inside of Midnight Commander
    PS1="$prompt$char "
  else
    PS1="╭$prompt\$(prompt::vcs)\$(prompt::venv)\n╰$char "
  fi
  unset prompt char
  export VIRTUAL_ENV_DISABLE_PROMPT=1
}

prompt::vcs() {
  local status
  if git::in_work_tree || git::in_git_dir; then
    status="git:${PROMPT_COLOR[branch]}$(git::branch)${PROMPT_COLOR[reset]}"
    git::is_changed && status+="${PROMPT_COLOR[changed]}*${PROMPT_COLOR[reset]}"
    git::is_staged  && status+="${PROMPT_COLOR[staged]}⊛${PROMPT_COLOR[reset]}"
    local action="$(git::action)"
    [[ -n $action ]] && status+="\e[38;5;9m $action${PROMPT_COLOR[reset]}"
  fi
  [[ -n $status ]] && echo -ne " [$status]"
}

prompt::venv() {
  [[ -n $VIRTUAL_ENV ]] && echo -en " (${PROMPT_COLOR[venv]}${VIRTUAL_ENV##*/}${PROMPT_COLOR[reset]})"
}

prompt::user_color() {
  (( EUID )) && echo -en "${PROMPT_COLOR[user]}" || echo -en "${PROMPT_COLOR[root]}"
}

prompt::user_char() {
  (( EUID )) && echo -en "${PROMPT_CHAR[user]}" || echo -en "${PROMPT_CHAR[root]}"
}

prompt::ssh_color() {
  [[ -n $SSH_TTY ]] && echo -en "${PROMPT_COLOR[ssh]}" || echo -en "${PROMPT_COLOR[host]}"
}

prompt::cmd() {
  local x
  [[ -z $MC_SID ]] && echo -en '\e[6n' && read -sdR x && (( ${x##*;} > 1 )) && echo
}

