# yaml.bash - YAML parser for Bash
#
# Copyright © 2016-2017 Vasiliy Polyakov
#
# Return codes:
#     0          OK
#     1  load    missing variable name (arg 1)
#     2  load    cannot read input file
#     3  load    unknown command as callback
#    64  lexer   unexpected character
#    65  parser  expected value
#    66  parser  expected string
#    67  parser  expected ':'
#    68  parser  expected ',' or '}'
#    69  parser  expected ',' or ']'
#    70  parser  expected end of file

bash_lib || return $(($?-1))
return "${EX[NOTIMPL]}"  # Not implemented

####  Source libraries  ##################################################{{{1
_yaml_lib="$(realpath -qe "${BASH_SOURCE[0]%/*}")"
. "$_yaml_lib/dbg.sh"
. "$_yaml_lib/errors.sh"
unset _yaml_lib

####  Constants  #########################################################{{{1
# Regular expressions for tokens {{{2
# Token is the outermost match
declare -A _yaml_regex
_yaml_regex[term]='(-{3}|\.{3}|[][?:,{}#&*!|>-])'
_yaml_regex[null]='(null)'
_yaml_regex[bool]='(true|false)'
_yaml_regex[int]='(0|-?[1-9][0-9]*)'
_yaml_regex[float]='(0|-?\.inf|\.nan|-?[1-9](\.[0-9]*[1-9])?(e[+-][1-9][0-9]*)?)'
declare -r _yaml_regex

####  Variables  #########################################################{{{1
declare -A _yaml_file
# [name] - input YAML file name or 'stdin'
# [line] - current line number
# [char] - current char number in line

declare -A _yaml_token
# [type] - type of a token: 'term', 'keyword', 'string', 'number' or 'space'
# [text] - textual content of a token

declare -A _yaml_array
# [name] - name of an array variable to load YAML data to
# [keys] - keys of structure to load

declare -i _yaml_done=0           # is loading completed succesfully?
declare -i _yaml_level=0          # current structure level
declare _yaml_line                # current parsed line
declare _yaml_callback=_yaml_echo # name of a callback function or command

####  Lexical analysis  ##################################################{{{1
_yaml_get_line() {
	unset _yaml_line

	if ! IFS='' read -r _yaml_line && [[ $? -ne 1 || ! $_yaml_line ]]; then
		return 65 # end of file
	fi

	(( _yaml_file[line]++, _yaml_file[char] = 1 )) || :

	return 0
}

_yaml_get_token() {
	local type

	_yaml_token[type]='' _yaml_token[text]=''

	if [[ ! $_yaml_line ]] && ! _yaml_get_line; then
		_yaml_token[type]='EOF' _yaml_token[text]='end of file'
		return 0
	fi

	for type in "${!_yaml_regex[@]}"; do
		if [[ $_yaml_line =~ ^${_yaml_regex[$type]} ]]; then
			_yaml_token[type]="$type"
			_yaml_token[text]="${BASH_REMATCH[1]}"
			_yaml_dbg_token

			_yaml_line="${_yaml_line:${#BASH_REMATCH[0]}}"
			(( _yaml_file[char] += ${#BASH_REMATCH[0]} )) || :

			if _yaml_token_is space; then
				_yaml_get_token
			fi

			return 0
		fi
	done

	_yaml_throw lexer "unexpected character '${_yaml_line:0:1}'" 64
}

_yaml_token_is() {
	local type="$1" text="$2"

	if [[ $text ]]; then
		[[ ${_yaml_token[type]} == "$type" && ${_yaml_token[text]} == "$text" ]]
	else
		[[ ${_yaml_token[type]} == "$type" ]]
	fi
}

####  Syntactic analysis  ################################################{{{1
_yaml_parse_directive() {
	_yaml_get_token

	return 0
}

_yaml_parse_document() {
	local -i d

	_yaml_get_token
	while _yaml_token_is term '%'; do
		(( d++ )) || :
		_yaml_parse_directive
		_yaml_get_token
	done
	if (( d )) && ! _yaml_token_is term '---'; then
		_yaml_expected "'---'"
	elif _yaml_token_is term '---'; then
		_yaml_get_token
	fi
	while ! _yaml_token_is term '...' || ! _yaml_token_is term '---' || ! _yaml_token_is EOF; do
		_yaml_parse_node
	done

	return 0
}

_yaml_parse_stream() {
	while ! _yaml_token_is EOF; do
		_yaml_parse_document
		_yaml_get_token
	done
	if ! _yaml_token_is EOF; then
		_yaml_expected "end of file"
	fi

	return 0
}
