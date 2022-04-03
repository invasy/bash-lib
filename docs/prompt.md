# Pretty prompt

Copyright © 2014-2022 [Vasiliy Polyakov](mailto:bash@invasy.dev).

## Prerequisites
- `lib.bash` - Bash scripting library;

@brief   Initialize prompt library.
@detail  Use in `.bashrc`.
@return  0
@brief   Print VCS prompt info.
@detail  Supported VCS:
- Git
@return  0
@stdout  VCS info.
@brief   Function that runs before every prompt rendering.
@detail  Check environment, update prompt, set title.
@return  0
@stdout  @c \\n if needed.
## See Also
- [Bash/Prompt customization — ArchWiki](https://wiki.archlinux.org/index.php/Bash/Prompt_customization "Bash/Prompt customization — ArchWiki")
- [nojhan/liquidprompt — GitHub](https://github.com/nojhan/liquidprompt "nojhan/liquidprompt — GitHub") — full-featured & carefully designed adaptive prompt for Bash & Zsh
- [Crazy POWERFUL Bash Prompt](https://www.askapache.com/linux/bash-power-prompt/ "Crazy POWERFUL Bash Prompt")
- [bashrc — Gentoo](https://gitweb.gentoo.org/repo/gentoo.git/tree/app-shells/bash/files/bashrc "bashrc — Gentoo")
