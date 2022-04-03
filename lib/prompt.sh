## # Pretty prompt
##
## Copyright © 2014-2022 [Vasiliy Polyakov](mailto:bash@invasy.dev).
##
## ## Prerequisites
## - `lib.bash` - Bash scripting library;
##
# TODO: rewrite documentation

bash_lib || return $(($?-1))

import colors
import git

declare -gA PROMPT_COLOR PROMPT_CHAR
declare -g  PROMPT_TITLE='\u@\h:\w\$ - Bash'

# Default prompt colors
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

# Default prompt characters
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

## @brief   Initialize prompt library.
## @detail  Use in `.bashrc`.
## @return  0
prompt::init() {
  local name

  for name in "${!PROMPT_COLOR[@]}"; do
    PROMPT_COLOR[$name]="$(SGR -p "${PROMPT_COLOR[$name]}")"
  done

  if [[ -z $debian_chroot && -r /etc/debian_chroot ]]; then
    debian_chroot="$(cat /etc/debian_chroot)"
  fi

  declare -r PROMPT_COLOR PROMPT_CHAR  # Make vars immutable
  declare -g PROMPT_COMMAND='prompt::cmd;'

  # Disable prompt update by Python virtual env activation script
  export VIRTUAL_ENV_DISABLE_PROMPT=1

  # Enable prompt expansion
  shopt -s promptvars &>/dev/null
}

## @brief   Print VCS prompt info.
## @detail  Supported VCS:
##          - Git
## @return  0
## @stdout  VCS info.
prompt::vcs() {
  local status action

  if git::in_work_tree || git::in_git_dir; then
    status="${PROMPT_COLOR[git]}${PROMPT_CHAR[git]}$R"
    status+="${PROMPT_COLOR[branch]}$(git::branch)$R"
    git::is_changed && status+="${PROMPT_COLOR[changed]}${PROMPT_CHAR[changed]}$R"
    git::is_staged  && status+="${PROMPT_COLOR[staged]}${PROMPT_CHAR[staged]}$R"
    action="$(git::action)"
    [[ $action ]] && status+="${PROMPT_COLOR[action]} $action$R"
    echo -n " [$status]"
  fi
}

## @brief   Function that runs before every prompt rendering.
## @detail  Check environment, update prompt, set title.
## @return  0
## @stdout  @c \\n if needed.
prompt::cmd() {
  history -a  # Append commands to a history file

  # Check if run in Midnight Commander
  if [[ $MC_SID ]]; then
    PS1='\u@\h:\w\$ '
    return
  fi

  local R="\[$SGR0\]" TSL='\[\e]2;' FSL='\e\\\]' u='user'
  local user at host dir venv char title chroot

  if (( EUID == 0 )); then
    u='root'  # Superuser
  fi

  # Set prompt fragments
  user="${PROMPT_COLOR[$u]}\u$R"
  at="${PROMPT_CHAR[at]}"
  host="${PROMPT_COLOR[host]}\h$R"
  dir="${PROMPT_COLOR[dir]}\w$R"
  char="${PROMPT_COLOR[$u]}${PROMPT_CHAR[$u]}$R"
  title="$PROMPT_TITLE"

  # Check if connected over SSH
  if [[ -n $SSH_TTY ]]; then
    at="${PROMPT_COLOR[ssh]}${PROMPT_CHAR[at]}$R"
    [[ -n $title ]] && title="[SSH] $title"
  fi

  # Check if Python virtual environment is active
  if [[ -n $VIRTUAL_ENV ]]; then
    venv=" (${PROMPT_COLOR[venv]}$(relpath "$VIRTUAL_ENV")$R)"
  fi

  # Set terminal title
  title="${title:+$TSL$title$FSL}"

  # Check if chrooted
  chroot="${debian_chroot:+($debian_chroot) }"

  # Set prompt
  PS1="$title╭$chroot$user$at$host:$dir$(prompt::vcs)$venv\n╰$char "

  # Add a new line if needed
  local stty column
  stty="$(stty -g)" && stty raw -echo min 0 \
  && echo -en '\e[6n' && read -rsdR column \
  && stty "$stty" && (( ${column##*;} > 1 )) && echo
}

## ## See Also
## - [Bash/Prompt customization — ArchWiki](https://wiki.archlinux.org/index.php/Bash/Prompt_customization "Bash/Prompt customization — ArchWiki")
## - [nojhan/liquidprompt — GitHub](https://github.com/nojhan/liquidprompt "nojhan/liquidprompt — GitHub") — full-featured & carefully designed adaptive prompt for Bash & Zsh
## - [Crazy POWERFUL Bash Prompt](https://www.askapache.com/linux/bash-power-prompt/ "Crazy POWERFUL Bash Prompt")
## - [bashrc — Gentoo](https://gitweb.gentoo.org/repo/gentoo.git/tree/app-shells/bash/files/bashrc "bashrc — Gentoo")

# vim: set et sw=2 ts=2 fdm=marker fmr=@{,@}:
