## @file    $XDG_DATA_HOME/bash/lib/arrays.sh
## @brief   Multidimensional arrays in Bash.
## @author  Vasiliy Polyakov
## @date    2016-2019
## @pre     bash           (GNU Bourne again shell).
## @pre     lib.bash       (Bash scripting library).
## @pre     sysexits.bash  (exit/return code constants).
## @todo    mda(): Add set and get functionality.
## @todo    Add exception handling.

source_guard || return $?
use sysexits

####  Subroutines  #######################################################{{{1
# aset_json <name> <keys> <type> [value]
aset_json() {
	(( __BASH_JSON__ )) || return ${EX[SOFTWARE]}

	local name="$1" keys="$2" type="$3" value="$4" k n t s
	[[ -n $name ]] || return 0

	case $type in
		object|array|string|number|bool|null)
			if [[ $keys ]]; then
				keys="${keys//[][]/_}"; keys="_${keys%_}"
				k="${keys##*__}"; n="$name${keys%__*}[$k]"
			fi ;;&
		object) t=A s='%' ;;&
		array)  t=a s='@' ;;&
		object|array)
			[[ $k ]] && echo "$n='^$s{$name$keys}' # $type ref"
			echo "typeset -$t '$name$keys'" ;;
		string) echo "$n=\"$value\"" ;;
		number) echo "$n=$value"     ;;
		null)   echo "$n='' # null"  ;;
		bool)   [[ $value == 'true' ]] \
			&& echo "$n=1 # true" \
			|| echo "$n=0 # false" ;;
	esac

	return 0
}

# mda [set] "<name>[keys]…=value"
# mda [get] "<name>[keys]…"
# mda keys  "<name>[keys]…"
mda() {
	local rx="^([A-Za-z][0-9A-Za-z_]*)((\[[^]]+\])*)(=('([^']*)'|\"(([^\"]|\\\")*)\"|.*))?\$"
	local cmd='get' name keys key value

	case $1 in
		keys) cmd="$1"; shift ;;
	esac

	eval "$(try)"; while true; do
		if [[ $1 =~ $rx ]]; then
			name="${BASH_REMATCH[1]}"
			keys="${BASH_REMATCH[2]}"
			value="${BASH_REMATCH[7]:-${BASH_REMATCH[6]:-${BASH_REMATCH[5]}}}"
		else
			throw -c USAGE -m "invalid array specification '%s'" "$1"
		fi

		if [[ $cmd == 'get' && $value ]]; then
			cmd='set'
		fi
		case $cmd in
			set|get)
				if [[ $keys ]]; then
					keys="${keys//[][]/_}"; keys="_${keys%_}"
					key="[${keys##*__}]" name="$name${keys%__*}"
				else
					throw -c USAGE -m "invalid array specification '%s'" "$1"
				fi
				;;&
			set)  declare -gA "$name"; eval "$name$key=\"$value\"" ;;
			get)  eval "echo \"\${$name$key}\"" ;;
			keys)
				if [[ $keys ]]; then
					keys="${keys//[][]/_}"; keys="_${keys%_}"
				fi
				eval "echo \"\${!$name$keys[@]}\""
				;;
		esac
	break; done; eval "$(end_try)"
}

# aset <name> <keys> <type> [value]
aset() {
	local name="$1" keys="$2" type="$3" value="$4" key
	local -i i

	[[ $name ]] || return 1
	[[ $keys && $keys =~ ^((\[([^]]+)\])*)\[([^]]+)\]$ ]] || return 2

	key="${BASH_REMATCH[4]}"
	keys="${BASH_REMATCH[1]//+([][])/_}"
	keys="${keys%%_}"; name="$name$keys"

	case $type in
		object)
			declare -p "$name" &>/dev/null || declare -gA "$name"
			value="%${name}_${key}"
			;;
		array)
			declare -p "$name" &>/dev/null || declare -ga "$name"
			value="@${name}_${key}"
			;;
		bool)
	esac

	return 0

	((DEBUG)) && echo "aset: array='$array' keys='$@'" >&2
	while true; do
		declare -p $array &>/dev/null || declare -gA $array
		key="$1"; shift
		((DEBUG)) && printf "%2u: %s[%s]\n" $i "$array" "$key" >&2
		[[ $1 ]] || break
		[[ $1 == '=' ]] && { shift; break; }
		eval $array[$key]="@${array}_${key}" array="${array}_${key}" key=""
		((DEBUG)) && printf "%2u: %s[%s]\n" $i "$array" "$key" >&2
		((i++))
	done
	if [[ $1 ]]; then
		eval $array[$key]="$1"
	else
		value=$(aget "$array" "$key")
		(($? == 254)) && unset $value
		unset $array[$key]
	fi
}

# aget <name> <index0> [<index1> …]
aget() {
	[[ $1 ]] || return ${EX[USAGE]}

	local -i i=0
	local name key value

	if [[ $1 =~ ([^]]+)((\[[^]]+\])*) ]]; then
		name="${BASH_REMATCH[1]}"
		set -- ${BASH_REMATCH[2]//[][]/ }
	else
		name="$1"; shift
	fi

	while (( $# )); do
		key="$1"; shift
		[[ -n $name ]] || return $i
		eval value="\${$name[$key]}"; ((i++))
		case ${value:0:1} in
			'@'|'%'|'*') name="${value:1}" ;;
			*) name=""
		esac
	done

	if [[ $name ]]; then
		echo "$name";  return -2
	elif [[ $value ]]; then
		echo "$value"; return 0
	else
		return $i
	fi
}

# akeys <array>
akeys() {
	[[ $1 ]] || return -1

	local -a keys
	local array key

	array="$1"
	eval keys=("\${!$array[@]}")
	for key in "${keys[@]}"; do
		echo "$key"
	done
}

# asize <array>
asize() {
	[[ $1 ]] || return -1

	eval "echo \"\${#$1[@]}\""
}

aprint() {
	local -a keys
	local array key value

	eval "keys=(\"\${!${array_name}[@]}\")"
	for key in "${keys[@]}"; do
		eval value="\${${array_name}[${key}]}"
		echo "$key: $value"
	done
}

# vim: set fen fdm=marker fmr={{{,}}}:
