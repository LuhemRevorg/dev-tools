# cdr

Find a directory by name with a breadth-first search and `cd` straight into it.

```zsh
cdr                 # go to your home directory
cdr target          # search under the current directory
cdr target ~/code   # search under a specific directory
```

It has two parts, because a program can't change the directory of the shell that launched it:

- **`src/cdr.cpp`** is compiled to `~/.local/bin/cdr`. It does the search and the cache, and prints the path it found.
- **`cdr.sh`** defines the `cdr` shell function, which runs the binary and does the `cd`. It also adds tab completion.

## Setup

You need `make` and `clang++` with C++17 support. On macOS, `xcode-select --install` provides both.

**1. Build the binary**

```zsh
mkdir -p ~/.local/bin
make
```

Run `make` again after changing `src/cdr.cpp`.

**2. Put `~/.local/bin` on your `PATH`**

Skip this if `echo $PATH` already includes it. Otherwise, add this line to `~/.zshrc`:

```zsh
export PATH="$PATH:$HOME/.local/bin"
```

**3. Copy the shell script to your home directory**

```zsh
cp cdr.sh ~/cdr.sh
```

Copy it again after editing `cdr.sh` in this repo.

**4. Source it from your shell config**

Add this line to the bottom of `~/.zshrc` (or `~/.bashrc`). In zsh it must come after `compinit` (oh-my-zsh runs it for you), so tab completion registers:

```zsh
source ~/cdr.sh
```

**5. Reload your shell and check**

```zsh
source ~/.zshrc
whence -w cdr   # zsh: should print "cdr: function"
```

## Tab completion

Press Tab after `cdr` to complete from the names `cdr` has already found. In zsh, each suggestion shows its path. It reads the cache on every Tab press, so new entries appear immediately. It doesn't complete directories you haven't searched for yet.

## Cache

The binary remembers successful searches in `~/.cache/cdr/map`, one tab-separated line per search:

```
<search root>	<name>	<resolved path>
```

A lookup only hits when both the search root and the name match. Otherwise `cdr` searches again and appends the new result. Cached paths aren't re-checked, so if a cached directory is deleted, remove its line or delete the file to reset the cache.

## Behavior

- **Matching:** the name must match exactly and is case-sensitive.
- **Which match wins:** the shallowest one. If two matches are at the same depth, it takes whichever it reaches first, which isn't sorted.
- **Skipped directories:** it doesn't search inside hidden directories, `node_modules` or `Library`. These can still match by name, so `cdr .claude` works, but nothing inside them is found.
- **Symlinks:** they aren't followed, so loops can't trap the search, but a symlink to a directory won't match.
- **Unreadable directories:** these are skipped silently.

## Return codes

| Code | Meaning |
| ---- | ------- |
| 0 | Found a match and changed directory |
| 1 | No match |
| 2 | Bad arguments or search root |
