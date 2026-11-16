#!/bin/bash
set -euo pipefail

: "${PROJECTS_DIR:?PROJECTS_DIR environment variable is not set}"
PRIVACY="--private"
if [ $# -eq 2 ]; then
  	PRIVACY="--public"
fi

if [ $# -ge 3 ]; then
	
	echo "Usage: $0 <project-name>" >&2
	exit 1
fi

PROJECT_NAME="$1"
TARGET="$PROJECTS_DIR/$PROJECT_NAME"

if [ -e "$TARGET" ]; then
  echo "Error: $TARGET already exists" >&2
  exit 1
fi

mkdir -p "$TARGET"
cd "$TARGET"
git init
gh repo create "$PROJECT_NAME" $PRIVACY --source=. --remote=origin
