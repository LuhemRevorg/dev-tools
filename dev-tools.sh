# dev-tools.sh - loads every tool in this repo into the current shell.
#
# Source this file; don't execute it. setup.sh adds the source line to
# ~/.zshrc. Add new tools to this file, not to ~/.zshrc.
#
# Works in zsh and bash.

# Locate this repo from the path of this file, so the repo can live anywhere.
if [ -n "${ZSH_VERSION:-}" ]; then
  DEV_TOOLS_DIR=${${(%):-%x}:A:h}
else
  DEV_TOOLS_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
fi
export DEV_TOOLS_DIR

# Compiled tools (the cdr binary) are installed to ~/.local/bin.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$PATH:$HOME/.local/bin" ;;
esac

# Where `project` creates new repos. Set PROJECTS_DIR before this file is
# sourced to override it.
export PROJECTS_DIR="${PROJECTS_DIR:-$HOME/Desktop/Projects}"

# cdr: BFS for a directory by name and cd into it, with tab completion.
# In zsh this must be sourced after compinit for completion to register.
source "$DEV_TOOLS_DIR/cdr/cdr.sh"

# project: create a git repo under $PROJECTS_DIR plus a private GitHub repo.
project() {
  "$DEV_TOOLS_DIR/project/project.sh" "$@"
}
