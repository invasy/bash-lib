## # Exit Codes
## `$XDG_DATA_HOME/bash/lib/sysexits.sh` — Bash scripting library error/exit/return codes.
##
## ## Copyright
## © 2016-2022 by [Vasiliy Polyakov](mailto:bash@invasy.dev).
##
## ## Prerequisites
## - `lib.bash` - Bash scripting library;
## - gawk (GNU AWK) — for constants list generation.
##
# shellcheck disable=SC2168
bash_lib || return $(($?-1))

## ## Variables
## - `BASH_ERROR` — Bash scripting library error/exit/return codes
## - `_BASH_ERROR` — reverse mapping of error codes to error names
## - `BASH_ERROR_NAMES` — exception names pattern
declare -gA BASH_ERROR

## ### General codes
## From [Advanced Bash-Scripting Guide][absg]:
BASH_ERROR[OK]=0            ##< successful termination, no error
BASH_ERROR[ERROR]=1         ##< catchall for general errors
BASH_ERROR[BUILTIN]=2       ##< misuse of shell builtins
##
## Values from 3 to 63 can be used freely.
##
## ### sysexits
_sysexits::sysexits() {
  type -f gawk &>/dev/null || return 1
  [[ -r /usr/include/sysexits.h ]] || return 2
  gawk -f "$BASH_LIB/bin/sysexits.awk" /usr/include/sysexits.h
}

BASH_ERROR[_BASE]=64        ##< base value for error messages
BASH_ERROR[USAGE]=64        ##< command line usage error
BASH_ERROR[DATAERR]=65      ##< data format error
BASH_ERROR[NOINPUT]=66      ##< cannot open input
BASH_ERROR[NOUSER]=67       ##< addressee unknown
BASH_ERROR[NOHOST]=68       ##< host name unknown
BASH_ERROR[UNAVAILABLE]=69  ##< service unavailable
BASH_ERROR[SOFTWARE]=70     ##< internal software error
BASH_ERROR[OSERR]=71        ##< system error (e.g., can't fork)
BASH_ERROR[OSFILE]=72       ##< critical OS file missing
BASH_ERROR[CANTCREAT]=73    ##< can't create (user) output file
BASH_ERROR[IOERR]=74        ##< input/output error
BASH_ERROR[TEMPFAIL]=75     ##< temp failure; user is invited to retry
BASH_ERROR[PROTOCOL]=76     ##< remote error in protocol
BASH_ERROR[NOPERM]=77       ##< permission denied
BASH_ERROR[CONFIG]=78       ##< configuration error
BASH_ERROR[_MAX]=78         ##< maximum listed value
## Generated by
## ```bash
## "$BASH_LIB/bin/sysexits.awk" /usr/include/sysexits.h
## ```

## ### From [Advanced Bash-Scripting Guide][absg]:
BASH_ERROR[EXEC]=126        ##< command invoked cannot execute
BASH_ERROR[NOCMD]=127       ##< command not found
BASH_ERROR[INVAL]=128       ##< invalid argument to `exit` builtin

## ### [Signals][signal]
## Exit codes have values `128 + SIG`:

_sysexits::signals() {
  type -f gawk &>/dev/null || return 1
  builtin kill -l | gawk -f "$BASH_LIB/bin/signals.awk"
}

# TODO: add descriptions
BASH_ERROR[SIGHUP]=129
BASH_ERROR[SIGINT]=130
BASH_ERROR[SIGQUIT]=131
BASH_ERROR[SIGILL]=132
BASH_ERROR[SIGTRAP]=133
BASH_ERROR[SIGABRT]=134
BASH_ERROR[SIGEMT]=135
BASH_ERROR[SIGFPE]=136
BASH_ERROR[SIGKILL]=137
BASH_ERROR[SIGBUS]=138
BASH_ERROR[SIGSEGV]=139
BASH_ERROR[SIGSYS]=140
BASH_ERROR[SIGPIPE]=141
BASH_ERROR[SIGALRM]=142
BASH_ERROR[SIGTERM]=143
BASH_ERROR[SIGURG]=144
BASH_ERROR[SIGSTOP]=145
BASH_ERROR[SIGTSTP]=146
BASH_ERROR[SIGCONT]=147
BASH_ERROR[SIGCHLD]=148
BASH_ERROR[SIGTTIN]=149
BASH_ERROR[SIGTTOU]=150
BASH_ERROR[SIGIO]=151
BASH_ERROR[SIGXCPU]=152
BASH_ERROR[SIGXFSZ]=153
BASH_ERROR[SIGVTALRM]=154
BASH_ERROR[SIGPROF]=155
BASH_ERROR[SIGWINCH]=156
BASH_ERROR[SIGPWR]=157
BASH_ERROR[SIGUSR1]=158
BASH_ERROR[SIGUSR2]=159
BASH_ERROR[SIGRTMIN]=160
BASH_ERROR[SIGRTMAX]=192

## ### Bash scripting library errors
BASH_ERROR[NOTIMPL]=250  ##< not implemented
BASH_ERROR[READLIB]=251  ##< cannot read library file
BASH_ERROR[INVPATH]=252  ##< invalid library path
BASH_ERROR[IMPORT]=253   ##< was not imported
BASH_ERROR[NOTINIT]=254  ##< not initialized
declare -gr BASH_ERROR

declare -ga _BASH_ERROR
local k
for k in "${!BASH_ERROR[@]}"; do
  [[ $k == _* ]] && continue
  # shellcheck disable=SC2034
  _BASH_ERROR[${BASH_ERROR[$k]}]=$k
done

local IFS='|'
# shellcheck disable=SC2034
declare -gr BASH_ERROR_NAMES="@(${!BASH_ERROR[*]})"
##
## ## See Also
## - [Advanced Bash-Scripting Guide: Appendix E. Exit Codes With Special Meanings](http://tldp.org/LDP/abs/html/exitcodes.html)
## - Exit status codes for system programs: `/usr/include/sysexits.h`
## - [signal(7)][signal]
##
## [absg]: https://tldp.org/LDP/abs/html/ "Advanced Bash-Scripting Guide"
## [signal]: https://man7.org/linux/man-pages/man7/signal.7.html "man 7 signal"

# vim: set et sw=2 ts=2 fen fdm=marker fmr=@{,@}:
