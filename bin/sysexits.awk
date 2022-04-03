#!/usr/bin/gawk -f
# $XDG_DATA_HOME/bash/bin/sysexits.awk - convert sysexits for use in bash-lib
#
# Copyright © 2016-2022 Vasiliy Polyakov <bash@invasy.dev>
#
# Usage:
#     gawk -f "$XDG_DATA_HOME/bash/bin/sysexits.awk" /usr/include/sysexits.h

/^#define\s+EX_/ {
	print gensub(/^#define\s+EX_([A-Z_]+)(\s+)([0-9]+)\s+\/\* (.+) \*\/$/, "EX[\\1]=\\3\\2# \\4", 1)
}
