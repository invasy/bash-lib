# $XDG_DATA_HOME/bash/scripts/signals.awk
# Print signal error codes for Bash.
#
# Copyright © 2016-2017 Vasiliy Polyakov <vp at psu dot ru>
#
# Usage:
#     builtin kill -l | gawk -f "$XDG_DATA_HOME/bash/scripts/signals.awk"
#   or
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

