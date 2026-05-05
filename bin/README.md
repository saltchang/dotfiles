# bin

## Update git

Usage:

```bash
update_git
```

## Screenshot (Hyprland)

Capture a region or the focused output, auto-save under `~/Pictures/Screenshots`, and edit in [satty](https://github.com/gabm/satty). In satty's toolbar, **Copy** puts the saved file's *path* on the clipboard so `Ctrl+V` pastes the path into terminal apps (e.g. Claude Code CLI), **Save** (`Ctrl+S`) overwrites the auto-saved file, and **Save as** (`Ctrl+Shift+S`) opens a file chooser.

Requires: `grim`, `slurp`, `satty`, `wl-clipboard`, `jq`, `hyprctl`.

```bash
screenshot region   # interactive selection (bound to $cmd+Shift+4 in hyprland)
screenshot output   # focused monitor    (bound to $cmd+Shift+3 in hyprland)
```
