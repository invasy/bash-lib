# signals.awk - print signal error codes for bash-lib
#
# Copyright © 2016-2019 Vasiliy Polyakov <invasy.v@gmail.com>
#
# Usage:
#     builtin kill -l | gawk -f "$XDG_DATA_HOME/bash/scripts/signals.awk"
#     /bin/kill -L | gawk -f "$XDG_DATA_HOME/bash/scripts/signals.awk"

BEGIN {
	FPAT = "[0-9]{1,3}|(SIG)?[A-Z][0-9A-Z+-]+"
	BASE = 128
}

{
	for (i = 1; i <= NF; i += 2) {
		code = BASE + $i
		name = $(i + 1)
		if (name  ~ /[+-]/) continue
		if (name !~ /^SIG/) name = "SIG" name
		print "EX[" name "]=" code
	}
}

