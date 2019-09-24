## @file    $XDG_DATA_HOME/bash/lib/sysexits.sh
## @brief   Bash exit/return codes.
## @author  Vasiliy Polyakov
## @date    2016-2019
## @pre     lib.bash  (Bash scripting library).
## @pre     gawk      (GNU AWK) for constants list generation.
## @see     Advanced Bash-Scripting Guide:
##          Appendix E. Exit Codes With Special Meanings
##          (http://tldp.org/LDP/abs/html/exitcodes.html)
## @see     Exit status codes for system programs
##          (/usr/include/sysexits.h
##          or http://linux.die.net/include/sysexits.h)

import_once || return $?

####  Functions  ##########################################################@{1
_sysexits::from_h() {
  type -f gawk &>/dev/null || return 1
  gawk -f "$BASH_LIB/sysexits.awk" /usr/include/sysexits.h
}

_sysexits::signals() {
  type -f gawk &>/dev/null || return 1
  builtin kill -l | gawk -f "$BASH_LIB/signals.awk"
}

####  Constants  ##########################################################@{1
## @enum   EX
## @brief  Exit codes.
declare -gA EX
EX[OK]=0            ##< successful termination

## @name  From Advanced Bash-Scripting Guide
## @{
EX[ERROR]=1         ##< catchall for general errors
EX[BUILTIN]=2       ##< misuse of shell builtins
## @}

## @name  Generated from /usr/include/sysexits.h
## @{
EX[_BASE]=64        ##< base value for error messages
EX[USAGE]=64        ##< command line usage error
EX[DATAERR]=65      ##< data format error
EX[NOINPUT]=66      ##< cannot open input
EX[NOUSER]=67       ##< addressee unknown
EX[NOHOST]=68       ##< host name unknown
EX[UNAVAILABLE]=69  ##< service unavailable
EX[SOFTWARE]=70     ##< internal software error
EX[OSERR]=71        ##< system error (e.g., can't fork)
EX[OSFILE]=72       ##< critical OS file missing
EX[CANTCREAT]=73    ##< can't create (user) output file
EX[IOERR]=74        ##< input/output error
EX[TEMPFAIL]=75     ##< temp failure; user is invited to retry
EX[PROTOCOL]=76     ##< remote error in protocol
EX[NOPERM]=77       ##< permission denied
EX[CONFIG]=78       ##< configuration error
EX[_MAX]=78         ##< maximum listed value
## @}

## @name  Bash scripting library exceptions
## @{
local -i n=EX[_MAX]+1
EX[_LIB_BASE]=$((n))   ##< base value for exceptions
EX[HOOK]=$((n++))      ##< unknown hook name
EX[UNDEF]=$((n++))     ##< undefined function
EX[_LIB_MAX]=$((n-1))  ##< maximum listed value for library
(( n >= 126 )) && echo "sysexits: warn: exceptions code over 126" >&2
## @}

## @name  From Advanced Bash-Scripting Guide
## @{
EX[EXEC]=126        ##< command invoked cannot execute
EX[NOCMD]=127       ##< command not found
EX[INVAL]=128       ##< invalid argument to exit
## @}

# 128+n - caught a signal @{
#eval "$(_sysexits::signals)"
EX[SIGHUP]=129
EX[SIGINT]=130
EX[SIGQUIT]=131
EX[SIGILL]=132
EX[SIGTRAP]=133
EX[SIGABRT]=134
EX[SIGEMT]=135
EX[SIGFPE]=136
EX[SIGKILL]=137
EX[SIGBUS]=138
EX[SIGSEGV]=139
EX[SIGSYS]=140
EX[SIGPIPE]=141
EX[SIGALRM]=142
EX[SIGTERM]=143
EX[SIGURG]=144
EX[SIGSTOP]=145
EX[SIGTSTP]=146
EX[SIGCONT]=147
EX[SIGCHLD]=148
EX[SIGTTIN]=149
EX[SIGTTOU]=150
EX[SIGIO]=151
EX[SIGXCPU]=152
EX[SIGXFSZ]=153
EX[SIGVTALRM]=154
EX[SIGPROF]=155
EX[SIGWINCH]=156
EX[SIGPWR]=157
EX[SIGUSR1]=158
EX[SIGUSR2]=159
EX[SIGRTMIN]=160
EX[SIGRTMAX]=192
declare -gr EX
#@}

declare -ga _EX
local k
for k in "${!EX[@]}"; do
  [[ $k == _* ]] && continue
  _EX[${EX[$k]}]="$k"
done

local IFS='|'
## @enum   EX_NAMES
## @brief  Exception names pattern.
declare -gr EX_NAMES="@(${!EX[*]})"

# vim: set et sw=2 ts=2 fen fdm=marker fmr=@{,@}:
