from kittens.tui.handler import result_handler
from kitty.boss import Boss
from kitty.constants import is_macos


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss: Boss) -> None:
    """file:///tmp/report.md → macOS: default; Linux: brave."""
    if len(args) != 2:
        return
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    program = "default" if is_macos else "brave"
    boss.open_url(args[1], program=program, cwd=window.cwd_of_child)
