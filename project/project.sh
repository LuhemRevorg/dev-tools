#!/bin/bash
set -euo pipefail

: "${PROJECTS_DIR:?PROJECTS_DIR environment variable is not set}"
PRIVACY="--public"

if [[ $# -ge 2 ]]; then
    case "$2" in
        --private) PRIVACY="--private" ;;
        --public)  ;;
        *) echo "Unknown option: $2 (expected --private or --public)" >&2; exit 1 ;;
    esac
else
    echo "No visibility given, defaulting to public repo"
fi

PROJECT_NAME="$1"
TARGET="$PROJECTS_DIR/$PROJECT_NAME"

if [ $PROJECT_NAME == "--usage" ]; then
	echo "Enter project name, if repo should be private enter '--private' after the project name"	
fi

if [ -e "$TARGET" ]; then
  echo "Error: $TARGET already exists" >&2
  exit 1
fi

mkdir -p "$TARGET"
cd "$TARGET"
git init
gh repo create "$PROJECT_NAME" $PRIVACY --source=. --remote=origin
