"""One agent status per row in horizontal tabs."""

import importlib
import sys
from pathlib import Path
from typing import TypedDict

plugin_dir = str(Path(__file__).resolve().parent)
if plugin_dir not in sys.path:
    sys.path.insert(0, plugin_dir)

import agent_status

# Reload shared labels too: kitty caches imports across config reloads.
importlib.reload(agent_status)
from agent_status import LABELS, PICKER_VAR, clean_text, status_text, window_status
from kitty.constants import is_wayland
from kitty.fast_data_types import (
    BOTTOM_EDGE, TOP_EDGE, DECAWM, GLFW_MOUSE_BUTTON_LEFT, GLFW_PRESS, GLFW_RELEASE,
    Region, get_boss, get_options, pt_to_px, set_options, set_tab_bar_render_data, viewport_for_window, wcswidth,
)
from kitty.tab_bar import CellRange, TabBar, as_rgb, draw_tab_with_powerline
from kitty.tabs import TabManager

WORKING_PALETTE = ((0x77, 0xDB, 0xF4), (0xBD, 0x93, 0xF9), (0xFF, 0x79, 0xC6))


class PaneHit(TypedDict):
    window_id: int
    row: int
    start: int
    end: int


def window_states(tab_id: int):
    tab = get_boss().tab_for_id(tab_id)
    if tab is None:
        return []
    states = []
    windows = (w for w in tab if not w.user_vars.get(PICKER_VAR))
    for window in windows:
        agent, status = window_status(window)
        if agent and status != 'exited':
            states.append((window, agent, status))
    return states


def fit(text: str, cells: int) -> str:
    text = clean_text(text)
    if wcswidth(text) <= cells:
        return text
    while text and wcswidth(text) > cells - 1:
        text = text[:-1]
    return text + '…' if cells > 0 else ''


def draw_agent_label(screen, text: str, status: str, active: bool) -> None:
    screen.cursor.bold = active
    screen.cursor.italic = False
    if active or status != 'working':
        screen.cursor.fg = as_rgb(0xFFFF55 if active else LABELS[status][2])
        screen.draw(text)
        return

    # Subtract time to move the colors right; terminal cell offsets keep alignment.
    phase = agent_status.time.monotonic() * 4
    start = screen.cursor.x
    for char in text:
        position = ((screen.cursor.x - start - phase) / 8) % len(WORKING_PALETTE)
        index = int(position)
        blend = position - index
        left = WORKING_PALETTE[index]
        right = WORKING_PALETTE[(index + 1) % len(WORKING_PALETTE)]
        color = sum(round(a + (b - a) * blend) << shift for a, b, shift in zip(left, right, (16, 8, 0)))
        screen.cursor.fg = as_rgb(color)
        screen.draw(char)


def draw_tab(draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data):
    if draw_data.tab_bar_edge in ('top', 'bottom') and screen.lines > 1:
        states = window_states(tab.tab_id)
        title = fit(tab.title, 24)
        # Reserve the arrow width so changing focus cannot resize tab columns.
        desired = max((wcswidth(status_text(agent, state, True)) for _, agent, state in states), default=12)
        tab = tab._replace(title=title + ' ' * max(0, desired - wcswidth(title)))
    return draw_tab_with_powerline(draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data)


def sync_tab_height() -> None:
    boss = get_boss()
    options = get_options()
    if options.tab_bar_edge not in (TOP_EDGE, BOTTOM_EDGE):
        return
    required, limits = [], []
    for os_window_id, manager in tuple(boss.os_window_map.items()):
        if not getattr(manager.tab_bar.draw_func, 'agent_multiline', False):
            continue
        _, region, _, height, _, cell_height = viewport_for_window(os_window_id)
        if region.width < 2 or cell_height < 1:
            continue
        count = max((len(window_states(tab.id)) for tab in manager.tabs_to_be_shown_in_tab_bar), default=0)
        points_per_pixel = 72 / pt_to_px(72, os_window_id)
        outer = pt_to_px(options.tab_bar_margin_height.outer, os_window_id)
        max_rows = max(0, (height - outer) // (3 * cell_height) - 1)
        required.append(count * cell_height * points_per_pixel)
        limits.append(max_rows * cell_height * points_per_pixel)
    if not limits:
        return
    # kitty shares margins across OS windows; protect the smallest window too.
    inner = min(max(required), min(limits))
    if inner == options.tab_bar_margin_height.inner:
        return
    options = options._replace(tab_bar_margin_height=options.tab_bar_margin_height._replace(inner=inner))
    set_options(options, is_wayland(), boss.args.debug_rendering, boss.args.debug_font_fallback)
    for manager in tuple(boss.os_window_map.values()):
        manager.resize()


def layout_multiline(bar: TabBar) -> None:
    bar._agent_native_layout()
    bar._agent_pane_hits = []
    if bar.is_vertical or not getattr(bar.draw_func, 'agent_multiline', False) or not bar.laid_out_once:
        return
    central, region, vw, vh, _, cell_height = viewport_for_window(bar.os_window_id)
    if region.width < 2 or cell_height < 1:
        return
    # The inner margin is reserved by kitty, so these rows never cover a shell.
    top, bottom = ((central.bottom, region.bottom) if bar.tab_bar_edge == BOTTOM_EDGE
                   else (region.top, central.top))
    rows = max(1, (bottom - top) // cell_height)
    if rows == 1:
        return
    if bar.tab_bar_edge == BOTTOM_EDGE:
        top = bottom - rows * cell_height
    else:
        bottom = top + rows * cell_height
    bar.screen.resize(rows, bar.screen.columns)
    bar.screen.reset_mode(DECAWM)
    bar.window_geometry = g = bar.window_geometry._replace(top=top, bottom=bottom, ynum=rows)
    expanded = Region((region.left, top, region.right, bottom, region.width, bottom - top))
    bar._last_viewport = (central, expanded, vw, vh)
    bar.update_blank_rects(central, expanded, vw, vh)
    set_tab_bar_render_data(bar.os_window_id, bar.screen, *g[:4])


def draw_pane_rows(bar: TabBar, tab_id: int, start: int, end: int) -> None:
    screen = bar.screen
    panes = window_states(tab_id)
    active_window = get_boss().os_window_map[bar.os_window_id].active_window
    available = screen.lines - 1
    for row, (window, agent, status) in enumerate(panes[:available], 1):
        screen.cursor.y, screen.cursor.x = row, start
        screen.cursor.bold = screen.cursor.italic = False
        if row == available and len(panes) > available:
            screen.cursor.fg = as_rgb(LABELS['unknown'][2])
            screen.draw(fit(f'{len(panes) - row + 1} more agents', end - start))
            return
        text = fit(status_text(agent, status, window is active_window), end - start)
        draw_agent_label(screen, text, status, window is active_window)
        bar._agent_pane_hits.append(PaneHit(window_id=window.id, row=row, start=start, end=start + wcswidth(text)))


def update_multiline(bar: TabBar, data) -> bool:
    bar._agent_pane_hits = []
    if bar.is_vertical or bar.screen.lines < 2 or not getattr(bar.draw_func, 'agent_multiline', False):
        return bar._agent_native_update(data)
    screen = bar.screen
    screen.cursor.x = screen.cursor.y = 0
    screen.cursor.bg = as_rgb(int(bar.draw_data.default_bg))
    screen.erase_in_display(2, False)
    changed = bar._agent_native_update(data)
    screen.cursor.bg = as_rgb(int(bar.draw_data.default_bg))
    for extent in bar.tab_extents:
        start, end = extent.x.start + 1, min(screen.columns, extent.x.end - 1)
        if end > start:
            draw_pane_rows(bar, extent.tab_id, start, end)
    bar.tab_extents = tuple(e._replace(y=CellRange(0, screen.lines - 1)) for e in bar.tab_extents)
    screen.cursor.x = screen.cursor.y = 0
    return changed


def handle_pane_click(manager: TabManager, x: float, y: float, button: int, modifiers: int, action: int) -> None:
    if button == GLFW_MOUSE_BUTTON_LEFT and action == GLFW_RELEASE and getattr(manager, '_agent_pane_press', False):
        manager._agent_pane_press = False
        return
    if button == GLFW_MOUSE_BUTTON_LEFT and action == GLFW_PRESS:
        manager._agent_pane_press = False
    bar = manager.tab_bar
    if button == GLFW_MOUSE_BUTTON_LEFT and action == GLFW_PRESS and not modifiers and not bar.is_vertical:
        g = bar.window_geometry
        if g.left <= x < g.right and g.top <= y < g.bottom:
            col, row = int((x - g.left) // bar.cell_width), int((y - g.top) // bar.cell_height)
            for hit in getattr(bar, '_agent_pane_hits', ()):
                if hit['row'] == row and hit['start'] <= col < hit['end']:
                    manager._agent_pane_press = True
                    manager.recent_tab_bar_mouse_events.clear()
                    get_boss().set_active_window(hit['window_id'], switch_os_window_if_needed=True)
                    return
    manager._agent_native_mouse(x, y, button, modifiers, action)


# These internal APIs are verified against kitty 0.48.2. Preserve the originals
# on the classes so reloading this module cannot stack wrappers recursively.
draw_tab.agent_multiline = True
if not hasattr(TabBar, '_agent_native_layout'):
    TabBar._agent_native_layout = TabBar.layout
    TabBar._agent_native_update = TabBar.update
    TabManager._agent_native_mouse = TabManager.handle_tab_bar_mouse
TabBar.layout = layout_multiline
TabBar.update = update_multiline
TabManager.handle_tab_bar_mouse = handle_pane_click
# Resize after polling, outside the draw callback, to avoid recursive layouts.
agent_status.start_monitor(sync_tab_height)
