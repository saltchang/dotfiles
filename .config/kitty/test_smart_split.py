"""Run: kitty +runpy 'import runpy; runpy.run_path(".config/kitty/test_smart_split.py")'"""

from pathlib import Path
from runpy import run_path
from types import SimpleNamespace

from kitty.layout.splits import Splits


handle_result = run_path(str(Path(__file__).with_name("smart_split.py")))["handle_result"]
layout = Splits(0, 0)
layout.pairs_root.one = 1
first = SimpleNamespace(id=1, geometry=SimpleNamespace(left=0, top=0, right=3834, bottom=1880))
right = SimpleNamespace(id=2, geometry=SimpleNamespace(left=0, top=0, right=1890, bottom=1880))
third = SimpleNamespace(id=3)
windows = SimpleNamespace(
    active_window=first,
    group_for_window=lambda window: SimpleNamespace(id=window.id),
    add_window=lambda window, **kwargs: SimpleNamespace(id=window.id),
)
launched = []
boss = SimpleNamespace(window_id_map={1: first, 2: right}, launch=lambda *args: launched.append(args))

for current, new in ((first, right), (right, third)):
    windows.active_window = current
    handle_result([], None, current.id, boss)
    location, cwd = launched[-1]
    if cwd != "--cwd=current":
        raise RuntimeError("New panes must preserve the working directory")
    layout.add_non_overlay_window(windows, new, location.removeprefix("--location="))

if not layout.pairs_root.horizontal or layout.pairs_root.two.horizontal:
    raise RuntimeError("Expected left pane + two stacked right panes")

handle_result([], None, -1, boss)
if len(launched) != 2:
    raise RuntimeError("Missing target window must not launch a pane")
print("PASS: first split left/right, second split top/bottom; cwd preserved; missing window ignored")
