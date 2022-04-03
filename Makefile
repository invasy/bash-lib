SHELL := /bin/bash

libs := sysexits colors git prompt title

srcs := $(addprefix lib/,$(addsuffix .sh,$(libs)))
docs := $(addprefix docs/,$(addsuffix .md,bash-lib $(libs)))

.PHONY: all check docs clean clean-docs dist-clean
all:

check: lib.bash $(srcs)
	@shellcheck --color=auto --shell=bash --format=gcc --external-sources $^

docs: $(docs)
	@bin/toc $^

docs/bash-lib.md: lib.bash
	@bin/bashdoc "$<" > "$@"

docs/%.md: lib/%.sh
	@bin/bashdoc "$<" > "$@"

clean:
	@-:

clean-docs:
	@-rm -rf docs/*.md

dist-clean: clean clean-docs
	@-:
