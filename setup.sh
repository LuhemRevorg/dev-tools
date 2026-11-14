#!/bin/bash
# setup.sh - builds the tools and hooks dev-tools.sh into ~/.zshrc.
#
#   ./setup.sh
#
# Safe to re-run: it rebuilds the cdr binary and rewrites the dev-tools block
# in ~/.zshrc instead of adding a second one. ~/.zshrc only gets a single
# `source .../dev-tools.sh` line; everything else lives in dev-tools.sh.
set -euo pipefail

REPO=$(cd -- "$(dirname -- "$0")" && pwd)
RC="${ZDOTDIR:-$HOME}/.zshrc"
BEGIN="# >>> dev-tools >>>"
END="# <<< dev-tools <<<"

for cmd in make clang++; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Error: $cmd not found. On macOS, run: xcode-select --install" >&2
    exit 1
  }
done
command -v gh >/dev/null 2>&1 || echo "Warning: gh not found; 'project' needs it (brew install gh)." >&2

# ---- build and install ----
mkdir -p "$HOME/.local/bin" "$HOME/.cache/cdr"
make -C "$REPO/cdr"
chmod +x "$REPO/project/project.sh"

# ---- ~/.zshrc ----
# Write $HOME rather than the expanded home path when the repo is under it.
case "$REPO" in
  "$HOME"/*) SRC="\$HOME/${REPO#"$HOME"/}/dev-tools.sh" ;;
  *) SRC="$REPO/dev-tools.sh" ;;
esac

touch "$RC"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# Drop any existing dev-tools block, plus the old setup that sourced a copy of
# cdr.sh from the home directory (dev-tools.sh sources cdr.sh from the repo).
awk -v begin="$BEGIN" -v end="$END" '
  $0 == begin { skip = 1; next }
  $0 == end   { skip = 0; next }
  skip        { next }
  /^[[:space:]]*(source|\.)[[:space:]]+("?(~|\$HOME|\$\{HOME\})"?)\/cdr\.sh[[:space:]]*$/ { next }
  /^# cdr: BFS for a directory by name/ { next }
  /^# \(source: .*cdr\.sh\)$/ { next }
  { print }
' "$RC" > "$tmp"

# Remove trailing blank lines so re-runs don't grow the file, then append the
# block at the end, which keeps it after compinit / oh-my-zsh.
sed -i '' -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$tmp"
{
  echo
  echo "$BEGIN"
  echo "# Managed by $REPO/setup.sh. Add tools to dev-tools.sh, not here."
  echo "source \"$SRC\""
  echo "$END"
} >> "$tmp"

if cmp -s "$tmp" "$RC"; then
  echo "$RC already up to date."
else
  cp "$RC" "$RC.dev-tools.bak"
  cat "$tmp" > "$RC"
  echo "Updated $RC (backup: $RC.dev-tools.bak)."
fi

echo "Done. Run 'source $RC' or open a new terminal."
