# Bash Scripting Library

## Prerequisites

- [Bash](https://www.gnu.org/software/bash/) (GNU Bourne again shell), version >= 4.0
- coreutils

## Shell Parameters

- `$BASH_LIB` — path to Bash library directory

## Return Codes

- `1` — current shell is not Bash.
- `2` — Bash version is not supported (less than 4.0).
- `3` — package `coreutils` is not installed.
- `255` — Bash lib was not initialized.

## Naming Convention

- `_<lib>_<name>` — private variables.
- `_<lib>::<name>` — private functions.
- `_<lib>::init` — library initialization.

## Links

- [GNU Bash Manual](https://www.gnu.org/software/bash/manual/)
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/)
- [Bash Hackers Wiki](https://wiki.bash-hackers.org/start)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
