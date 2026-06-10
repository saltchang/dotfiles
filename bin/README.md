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

## Translate (Hyprland)

Translate text to Traditional Chinese with a Google Translate-style UX, built on [Dialect](https://github.com/dialect-app/dialect) (GTK translation app). Two entry points:

- `translate` — select a region, OCR it (English + Traditional Chinese), copy the recognised text to the clipboard, then open it in Dialect where the text is **editable with live re-translation** (fix OCR mistakes and watch the translation update). Bound to `$cmd+Shift+2`.
- **walker** — `$cmd+Space` opens the regular walker launcher (apps + calc); typing a sentence (anything with a space or CJK characters) adds a「翻譯 → 正體中文」entry — press Return to open it in Dialect. Backed by the custom elephant Lua menu `.config/elephant/menus/translate.lua` (requires `elephant-menus`). To translate a single word, add a trailing space.

The screen capture is Wayland-native (`grim`/`slurp`), so there are no screen-grab quirks on Hyprland — Dialect only ever receives plain text.

Requires: `grim`, `slurp`, `tesseract` (with `eng` + `chi_tra`), `dialect`, `wl-clipboard`, `libnotify`.

```bash
translate   # OCR a region → clipboard + editable live translation (bound to $cmd+Shift+2)
```
