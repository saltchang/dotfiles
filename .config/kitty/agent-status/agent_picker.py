"""Alt+a opens a live, scrollable picker for all agent windows."""

from __future__ import annotations

import curses
import json
import locale
import os
import subprocess
import time
from contextlib import suppress
from typing import TypedDict

from agent_status import PICKER_VAR, STATE_VAR, clean_text, describe, status_text
from kittens.tui.handler import kitten_ui, result_handler


class Process(TypedDict):
    cmdline: list[str]


class Pane(TypedDict):
    id: int
    title: str
    user_vars: dict[str, str]
    foreground_processes: list[Process]


class Tab(TypedDict):
    id: int
    title: str
    windows: list[Pane]


class OSWindow(TypedDict):
    id: int
    tabs: list[Tab]


class Row(TypedDict):
    window_id: int
    label: str
    status: str


def rows_for_windows(windows: list[OSWindow], kitty_pid: int) -> list[Row]:
    rows = []
    for os_window in windows:
        for tab in os_window["tabs"]:
            panes = [w for w in tab["windows"] if not w["user_vars"].get(PICKER_VAR)]
            for index, pane in enumerate(panes, 1):
                agent, status = describe(
                    pane["user_vars"].get(STATE_VAR, ""),
                    kitty_pid,
                    pane["id"],
                    [p["cmdline"] for p in pane["foreground_processes"]],
                )
                if not agent or status == "exited":
                    continue
                location = f"OS {os_window['id']} / {tab['title']} / {index}"
                text = f"{status_text(agent, status)}  {location}  {pane['title']}"
                rows.append(
                    Row(window_id=pane["id"], label=clean_text(text), status=status)
                )
    return rows


def remote(*args: str) -> str:
    result = main.remote_control(args, capture_output=True, text=True, timeout=2)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "kitty remote control failed")
    return result.stdout


def picker(screen) -> int | None:
    screen.encoding = "utf-8"
    curses.curs_set(0)
    screen.timeout(100)
    curses.start_color()
    curses.use_default_colors()
    for number, color in enumerate(
        (
            curses.COLOR_MAGENTA,
            curses.COLOR_GREEN,
            curses.COLOR_CYAN,
            curses.COLOR_RED,
            curses.COLOR_YELLOW,
        ),
        1,
    ):
        curses.init_pair(number, color, -1)
    colors = {
        "waiting": 1,
        "done": 2,
        "working": 3,
        "background": 3,
        "error": 4,
        "reconnecting": 5,
    }
    windows: list[OSWindow] = []
    selected_id = 0
    next_refresh = 0.0
    attention_only = False
    error = ""
    while True:
        if time.monotonic() >= next_refresh:
            try:
                windows = json.loads(remote("ls"))
                error = ""
            except (
                OSError,
                ValueError,
                RuntimeError,
                subprocess.TimeoutExpired,
            ) as exc:
                # Keep the last successful snapshot visible during a connection error.
                error = clean_text(str(exc))
            next_refresh = time.monotonic() + 1
        rows = rows_for_windows(windows, int(os.environ["KITTY_PID"]))
        visible = [
            r
            for r in rows
            if not attention_only or r["status"] in ("waiting", "done", "error")
        ]
        selected = next(
            (i for i, r in enumerate(visible) if r["window_id"] == selected_id), 0
        )
        if visible:
            selected_id = visible[selected]["window_id"]
        height, width = screen.getmaxyx()
        page = max(1, height - 3)
        offset = max(0, selected - page + 1)
        screen.erase()
        lines = [("Agent windows — ↑↓/jk Enter跳轉 a篩選 q關閉", curses.A_BOLD)]
        for i, row in enumerate(visible[offset : offset + page], offset):
            style = curses.color_pair(colors.get(row["status"], 0))
            lines.append(
                (row["label"], style | (curses.A_REVERSE if i == selected else 0))
            )
        for y, (text, style) in enumerate(lines[: max(0, height - 1)]):
            with suppress(curses.error):
                screen.addnstr(y, 0, text, max(0, width - 1), style)
        footer = (
            error
            or f"{len(visible)} agents · {'待處理／完成' if attention_only else '全部'} · 每秒更新"
        )
        with suppress(curses.error):
            screen.addnstr(max(0, height - 1), 0, footer, max(0, width - 1))
        screen.refresh()
        key = screen.getch()
        if key in (ord("q"), 27):
            return
        if key == ord("a"):
            attention_only = not attention_only
        if key in (10, 13, curses.KEY_ENTER) and visible and not error:
            return selected_id
        movement = {
            ord("j"): 1,
            curses.KEY_DOWN: 1,
            ord("k"): -1,
            curses.KEY_UP: -1,
            curses.KEY_NPAGE: page,
            curses.KEY_PPAGE: -page,
        }
        if visible and key in movement:
            selected = min(len(visible) - 1, max(0, selected + movement[key]))
            selected_id = visible[selected]["window_id"]


@kitten_ui(allow_remote_control=True)
def main(args):
    locale.setlocale(locale.LC_ALL, "")
    remote(
        "set-user-vars",
        "--match",
        f"id:{os.environ['KITTY_WINDOW_ID']}",
        f"{PICKER_VAR}=1",
    )
    remote(
        "set-window-title",
        "--match",
        f"id:{os.environ['KITTY_WINDOW_ID']}",
        "Agent windows",
    )
    return curses.wrapper(picker)


@result_handler()
def handle_result(args, answer, target_window_id, boss) -> None:
    if answer in boss.window_id_map:
        boss.set_active_window(answer, switch_os_window_if_needed=True)
