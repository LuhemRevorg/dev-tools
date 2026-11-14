# dev-tools

My personal dev-tools, I could create a CLI...... idk too much of a hassle

## Setup

```zsh
./setup.sh
source ~/.zshrc
```

`setup.sh` builds the compiled tools into `~/.local/bin` and adds one block to the end of `~/.zshrc` that sources `dev-tools.sh`. `dev-tools.sh` sets up the tools: `PATH`, `PROJECTS_DIR` (default `~/Desktop/Projects`), `cdr` and `project`. You can re-run `setup.sh` safely. It rebuilds the tools and rewrites its block instead of adding a second one, and it backs up the old file to `~/.zshrc.dev-tools.bak`.

To add a tool, put its setup in `dev-tools.sh`, not in `~/.zshrc`.

## Tools

- [`cdr`](cdr/README.md): find a directory by name (BFS) and `cd` into it
- [`project`](project/README.md): create a local git repo plus a private GitHub repo
