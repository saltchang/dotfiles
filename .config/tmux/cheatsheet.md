# tmux cheatsheet (zellij-style modal)

Prefix: Ctrl+b

## Always-active (root table, no prefix needed)

| Key             | Action                                              |
| --------------- | --------------------------------------------------- |
| Alt + h / Left  | Focus pane left (at left edge → previous tab)       |
| Alt + l / Right | Focus pane right (at right edge → next tab)         |
| Alt + j / Down  | Focus pane down                                     |
| Alt + k / Up    | Focus pane up                                       |
| Alt + =  /  +   | Resize pane larger                                  |
| Alt + -         | Resize pane smaller                                 |
| Alt + f         | Toggle zoom (fullscreen)                            |
| Alt + g         | Open popup (float)                                  |
| Alt + n         | New pane (smart split — picks by pane aspect ratio) |
| Alt + d         | New pane (split down)                               |
| Alt + t         | New tab (window) in current path                    |
| Alt + Shift + X | Close current pane                                  |
| Alt + i         | Move current tab left                               |
| Alt + o         | Move current tab right                              |

## Prefix keys (press Ctrl+b first)

| Key | Enters        |
| --- | ------------- |
| p   | Pane mode     |
| t   | Tab mode      |
| r   | Resize mode   |
| s   | Scroll mode   |
| o   | Session mode  |
| m   | Move mode     |
| R   | Reload config |
| ?   | This cheatsheet |

## Pane mode (Ctrl+b p)

| Key          | Action                              |
| ------------ | ----------------------------------- |
| h/j/k/l      | Focus pane (stays in mode)          |
| Tab          | Cycle panes                         |
| c            | Rename pane title                   |
| d            | Split down                          |
| n / r        | Split right                         |
| w            | Open popup (float)                  |
| f            | Toggle zoom                         |
| x            | Close pane                          |
| z            | Toggle pane-border-status           |
| Enter / Esc  | Back to root                        |

## Tab (window) mode (Ctrl+b t)

| Key         | Action                              |
| ----------- | ----------------------------------- |
| h/k / Left  | Previous window                     |
| l/j / Right | Next window                         |
| 1-9         | Jump to window N                    |
| n           | New window                          |
| r           | Rename window                       |
| b           | Break current pane to new window    |
| [           | Swap window left                    |
| ]           | Swap window right                   |
| s           | Toggle synchronize-panes            |
| x           | Close window                        |
| Enter / Esc | Back to root                        |

## Resize mode (Ctrl+b r)

| Key         | Action                              |
| ----------- | ----------------------------------- |
| h/j/k/l     | Resize 2 cells toward direction     |
| H/J/K/L     | Resize 5 cells (larger step)        |
| + / =       | Zoom toggle                         |
| Enter / Esc | Back to root                        |

## Scroll mode (Ctrl+b s)

Any direction key drops into tmux copy-mode. In copy-mode:

| Key    | Action                                     |
| ------ | ------------------------------------------ |
| v      | Begin selection                            |
| y      | Copy selection (OSC 52 to system clipboard)|
| /      | Search backward                            |
| n / N  | Next / previous search match               |
| Esc    | Exit copy-mode                             |

## Session mode (Ctrl+b o)

| Key         | Action                              |
| ----------- | ----------------------------------- |
| d           | Detach                              |
| w / s       | Fuzzy session / window picker       |
| Enter / Esc | Back to root                        |

## Move mode (Ctrl+b m)

| Key         | Action                              |
| ----------- | ----------------------------------- |
| h/j/k/l     | Swap with neighbour in direction    |
| n / Tab     | Cycle swap forward                  |
| p           | Cycle swap backward                 |
| Enter / Esc | Back to root                        |

## Plugin-provided

- **Ctrl+b + I** — install declared TPM plugins
- **Ctrl+b + U** — update TPM plugins
- **Ctrl+b + Space** — tmux-which-key popup (if installed)

## Session persistence (tmux-resurrect)

- **Ctrl+b + Ctrl+s** — manual save
- **Ctrl+b + Ctrl+r** — manual restore
- Auto-save every 5 min and auto-restore on launch (tmux-continuum)
