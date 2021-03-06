## @file    $XDG_DATA_HOME/bash/lib/prompt.sh
## @brief   Bash functions for pretty prompt.
## @author  Vasiliy Polyakov
## @date    2019
## @pre     lib.bash  (Bash scripting library).
## @see https://wiki.archlinux.org/index.php/Bash/Prompt_customization
## @see https://github.com/nojhan/liquidprompt
## @see https://www.askapache.com/linux/bash-power-prompt/
## @see https://gitweb.gentoo.org/repo/gentoo.git/tree/app-shells/bash/files/bashrc

bash_lib || return $(($?-1))

import colors
import git

declare -gA PROMPT_COLOR PROMPT_CHAR
declare -g  PROMPT_TITLE='\u@\h:\w\$ - Bash'

PROMPT_COLOR[user]='fg=10 bold'
PROMPT_COLOR[root]='fg=9 bold'
PROMPT_COLOR[host]='fg=6 fg256=36 bold'
PROMPT_COLOR[dir]='fg=15 bold'
PROMPT_COLOR[git]='fg=10'
PROMPT_COLOR[branch]='fg8=5 fg16=13 fg256=207'
PROMPT_COLOR[changed]='fg=3'
PROMPT_COLOR[staged]='fg=11'
PROMPT_COLOR[action]='fg=9'
PROMPT_COLOR[ssh]='fg=9 bold'
PROMPT_COLOR[venv]='fg=3 fg256=190'

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
  local name

  for name in "${!PROMPT_COLOR[@]}"; do
    PROMPT_COLOR[$name]="$(SGR -p ${PROMPT_COLOR[$name]})"
  done

  if [[ -z $debian_chroot && -r /etc/debian_chroot ]]; then
    debian_chroot="$(cat /etc/debian_chroot)"
  fi

  declare -r PROMPT_COLOR PROMPT_CHAR
  declare -g PROMPT_COMMAND='prompt::cmd;'
  export VIRTUAL_ENV_DISABLE_PROMPT=1
}

prompt::vcs() {
  local status action

  if git::in_work_tree || git::in_git_dir; then
    status="${PROMPT_COLOR[git]}${PROMPT_CHAR[git]}$R"
    status+="${PROMPT_COLOR[branch]}$(git::branch)$R"
    git::is_changed && status+="${PROMPT_COLOR[changed]}${PROMPT_CHAR[changed]}$R"
    git::is_staged  && status+="${PROMPT_COLOR[staged]}${PROMPT_CHAR[staged]}$R"
    action="$(git::action)"
    [[ -n $action ]] && status+="${PROMPT_COLOR[action]} $action$R"

    echo -n " [$status]"
  fi
}

prompt::cmd() {
  history -a

  if [[ -n $MC_SID ]]; then # in Midnight Commander
    PS1='\u@\h:\w\$ '
    return
  fi

  local R="\[$SGR0\]" TSL='\[\e]2;' FSL='\e\\\]' u='user'
  local user at host dir venv char title chroot
  (( EUID )) || u='root' # Superuser

  # Set prompt fragments
  user="${PROMPT_COLOR[$u]}\u$R"
  at="${PROMPT_CHAR[at]}"
  host="${PROMPT_COLOR[host]}\h$R"
  dir="${PROMPT_COLOR[dir]}\w$R"
  char="${PROMPT_COLOR[$u]}${PROMPT_CHAR[$u]}$R"
  title="$PROMPT_TITLE"

  if [[ -n $SSH_TTY ]]; then # connected over SSH
    at="${PROMPT_COLOR[ssh]}${PROMPT_CHAR[at]}$R"
    [[ -n $title ]] && title="[SSH] $title"
  fi
  if [[ -n $VIRTUAL_ENV ]]; then # in Python virtual environment
    venv=" (${PROMPT_COLOR[venv]}$(relpath "$VIRTUAL_ENV")$R)"
  fi

  title="${title:+$TSL$title$FSL}"
  chroot="${debian_chroot:+($debian_chroot) }"

  # Set prompt
  PS1="$title╭$chroot$user$at$host:$dir$(prompt::vcs)$venv\n╰$char "

  local stty column
  stty="$(stty -g)" && stty raw -echo min 0 \
  && echo -en '\e[6n' && read -sdR column \
  && stty "$stty" && (( ${column##*;} > 1 )) && echo
}

# vim: set et sw=2 ts=2:
