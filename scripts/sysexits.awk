# $XDG_DATA_HOME/bash/scripts/sysexits.awk
# Convert sysexits for library use.
#
# Copyright © 2016-2017 Vasiliy Polyakov <vp at psu dot ru>
#
# Usage:
#     gawk -f "$XDG_DATA_HOME/bash/scripts/sysexits.awk" /usr/include/sysexits.h

/^#define\s+EX_/ {
	print gensub(/^#define\s+EX_([A-Z_]+)(\s+)([0-9]+)\s+\/\* (.+) \*\/$/,
		"EX[\\1]=\\3\\2# \\4", 1)
}
