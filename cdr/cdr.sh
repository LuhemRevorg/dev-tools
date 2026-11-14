# cdr.sh - find a directory by name (breadth-first) and cd into it.
#
# Source this file from your shell rc; do not execute it. The search and the
# cache live in the C++ binary (src/cdr.cpp, built to ~/.local/bin/cdr), which
# prints the path. A program can't change the directory of the shell that
# launched it, so this function runs the binary and does the cd.
#
#   cdr                  cd to $HOME
#   cdr name             search under the current directory
#   cdr name /some/dir   search under /some/dir
#
# Works in zsh and bash.

# Must match STORE in src/cdr.cpp. Only tab completion reads it here.
CDR_MAP="$HOME/.cache/cdr/map"

cdr() {
  local dest
  dest=$(command cdr "$@") && cd -- "$dest"
}

# ---- tab completion: offers the names in the cache ----
if [ -n "${ZSH_VERSION:-}" ]; then
  _cdr() {
    [[ -r $CDR_MAP ]] || return 1
    local -a names
    local n p
    while IFS=$'\t' read -r _ n p; do
      [[ -n $n ]] && names+=("${n//:/\\:}:${p//:/\\:}")
    done < "$CDR_MAP"
    _describe -t directories 'cdr target' names
  }
  # compdef only exists after compinit; source this file after it.
  type compdef >/dev/null 2>&1 && compdef _cdr cdr
elif [ -n "${BASH_VERSION:-}" ]; then
  _cdr_bash() {
    [ -r "$CDR_MAP" ] || return 0
    local cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=($(compgen -W "$(cut -f2 "$CDR_MAP")" -- "$cur"))
  }
  complete -F _cdr_bash cdr
fi
