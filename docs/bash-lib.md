# bash-lib
`$XDG_DATA_HOME/bash/lib.bash` — Bash scripting library.

Copyright © 2016-2022 [Vasiliy Polyakov](mailto:bash@invasy.dev).

## Prerequisites
- [Bash](https://www.gnu.org/software/bash/) — GNU Bourne again shell, version >= 4.0.
- `coreutils` package — `dirname`, `realpath`.

## Source Guard
When sourced **bash-lib** returns these codes on error:
- `1` — current shell is not Bash;
- `2` — Bash version is not supported;
- `3` — package `coreutils` is not installed.

## XDG Base Directories
**bash-lib** supports [XDG Base Directories Specification][xdg].

---

## Variables
- `$BASH_LIB` — path to the **bash-lib** directory.

## Options
### General Options
- [x] `lastpipe` — execute the last cmd of a pipeline in current shell;
- [x] `xpg_echo` — `echo` expands escape sequences.
### Globbing
- [x] `globstar` — `**` recurses through subdirectories;
- [x] `extglob` — enable extended pattern matching;
- [ ] `failglob` — failed patterns do not result in an error;
- [x] `nullglob` — patterns that match no files are expand to empty string.

---

## Functions

### bash_lib
Library header.
#### Usage
```bash
bash_lib [-n name] [-v version] [-x] || return $(($?-1))
```
_at the beginning of the library file (`lib/*.sh`)_
#### Options
- `-n name` — library name (default: determine from filename);
- `-v version` — library version (default: `1.0.0`);
- `-x` — library is not implemented yet.
#### Returns
- `0` — OK;
- `1` — library was already imported (_not an error_);
- `127` — `bash_lib: command not found` (_error code from Bash_);
- `250` — library was not implemented yet;
- `252` — invalid library file path;
- `253` — this library was not imported properly;
- `254` — **bash-lib** was not initialized properly.

### import
Imports Bash library.
#### Usage
```bash
import library [args …]
```
#### Arguments
- `$1` — library name;
- `$@` — additional parameters for the library.
#### Returns
- `0` — OK;
- `1` — missing library name (arg 1);
- `251` — cannot read library file;
- `254` — `bash-lib` was not initialized correctly.

### is_sourced
Is this script sourced?
#### Usage
```bash
is_sourced [frame]
```
#### Arguments
- `$1` - function call stack frame number (⩾1, default: `1`).
#### Returns
- `0` — sourced;
- `1` — not sourced.

### is_imported
Is this script/library imported?
#### Usage
```bash
is_imported [frame]
```
#### Arguments
- `$1` — function call stack frame number (⩾1, default: `1`).
#### Returns
- `0` — imported;
- `1` — not imported.

### semver
Parses semantic version string.
#### Usage
```bash
semver version
```
#### Arguments
- `$1` — version string.
#### Returns
- `0` — OK;
- `1` — cannot parse version string.
#### Stdout
```
major minor patch
[pre-release …]
[build …]
```
#### See Also
- [Semantic Versioning][semver].

### semvercmp
Compares two semantic version strings.
#### Usage
```bash
semvercmp version1 version2
```
#### Arguments
- `$1` — the first version string;
- `$2` — the second version string.
#### Returns
- `0` — both version strings have equal precedence;
- `1` — the first version string has higher precedence;
- `2` — the second version string has higher precedence;
- `254` — cannot parse the second version string;
- `255` — cannot parse the first version string.
#### See Also
- [Semantic Versioning][semver].

### die
Prints error message and exit with error code.
#### Usage
```bash
die [-n name] [-c code] format [arguments …]
```
#### Options
- `-n name` — script name (default: determine from filename);
- `-c code` — exit code (default: `1`).
#### Arguments
- `$1` — format string;
- `$@` — message arguments.
#### Stdout
Formatted error message.

### a2re
Converts an array to a regular expression matching array values.
#### Usage
```bash
a2re value …
```
#### Arguments
- `$@` — array values.
#### Stdout
Regular expression for the array.

### in_array
Checks if a `needle` is in a `haystack` array.
#### Usage
```bash
in_array array value
```
#### Arguments
- `$1` — `haystack` — name of array variable;
- `$2` — `needle` — value to find.
#### Returns
- `0` — found;
- `1` — not found;
- `254` — missing argument 2;
- `255` — missing argument 1.

### `relpath`
Prints file path relative to a specified or current directory.
#### Usage
```bash
relpath filename base
```
#### Arguments
- `$1` — filename;
- `$2` — directory name (default: `$PWD`).
#### Returns
- `$?` — exit code from `realpath`.
#### Stdout
Relative path.

---

## Libraries
- [Exit Codes](sysexits.md)
- [Color terminal support](colors.md)
- [Git](git.md)
- [Pretty prompt](prompt.md)
- [Terminal and window titles](title.md)

---

## See Also
- [GNU Bash Manual](https://www.gnu.org/software/bash/manual/)
- [Advanced Bash-Scripting Guide][absg]
- [Bash Hackers Wiki](https://wiki.bash-hackers.org/start)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

[absg]: https://tldp.org/LDP/abs/html/ "Advanced Bash-Scripting Guide"
[xdg]: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html "XDG Base Directories Specification"
[semver]: https://semver.org/ "Semantic Versioning"
