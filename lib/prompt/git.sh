## @file    $XDG_DATA_HOME/bash/prompt/git.bash
## @brief   Bash scripting library.
## @author  Vasiliy Polyakov
## @date    2017
## @pre     bash       (GNU Bourne again shell).
## @pre     lib.bash   (Bash scripting library).

type git &>/dev/null || return 0

_prompt_git_parse_branch_line() {
	local branch_line="$1"
}

_prompt_git_status() {
	LC_ALL=C git status --porcelain=2 --branch \
		--untracked-files=${PROMPT_GIT_UNTRACKED:-all} \
		2>/dev/null || return 0
}

_prompt_git() {
	local status branch
	local -i staged=0 changed=0 submodules=0 conflicts=0 untracked=0
	while IFS='' read -r line || [[ $line ]]; do
		status=${line:0:2}
		case $status in
			\#\#) branch="${line/\.\.\./^}" ;;
			\?\?) (( untracked++ )) ;;
			U?|?U|AA|DD) (( conflicts++ )) ;;
			?M|?D) (( changed++ )) ;;&
			?\ ) ;;&
			U?) (( conflicts++ )) ;;
			\ ?) ;;
			??) (( staged++ )) ;;
		esac
	done
}

test_case() {
	local line="AM file"
	local status=${line:0:2} branch_line
	local -i staged=0 changed=0 conflicts=0 untracked=0
	case $status in
		\#\#) branch_line="${line/\.\.\./^}" ;;
		\?\?) (( untracked++ )) ;;
		U?|?U|AA|DD) (( conflicts++ )) ;;
		?M|?D) (( changed++ )); echo "Y='M' or Y='D'" ;;&
		?\ ) echo "Y=' '" ;;&
		U?) (( conflicts++ )) ;;
		\ ?) ;;
		??) (( staged++ )) ;;
	esac

	echo "changed   ${changed}"
	echo "staged    ${staged}"
	echo "conflicts ${conflicts}"
	echo "untracked ${untracked}"

	return 0
}

test_case
