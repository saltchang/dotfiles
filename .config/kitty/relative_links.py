import os
from pathlib import Path
from urllib.parse import unquote, urlsplit

from kittens.tui.handler import result_handler
from kitty.boss import Boss
from kitty.child import cwd_of_process


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss: Boss) -> None:
    """Open docs/report.md as file:///work/docs/report.md when the pane cwd is /work."""
    if len(args) != 2:
        return
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    parts = urlsplit(args[1])
    path = unquote(parts.path, errors="surrogateescape")
    if parts.scheme or parts.netloc or not path or Path(path).is_absolute():
        return

    try:
        foreground_pgid = os.tcgetpgrp(window.child.child_fd)
        cwd = cwd_of_process(foreground_pgid)
    except OSError:
        cwd = None
    if not cwd or not Path(cwd).is_absolute():
        boss.show_error("無法開啟相對連結", "無法取得來源 pane 的工作目錄，已停止開啟以免使用錯誤路徑。")
        return

    uri = (Path(cwd) / path).as_uri()
    target = urlsplit(uri)._replace(query=parts.query, fragment=parts.fragment).geturl()
    boss.open_url(target, cwd=cwd)
