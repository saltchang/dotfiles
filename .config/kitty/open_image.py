from kittens.tui.handler import result_handler
from kitty.boss import Boss
from kitty.utils import open_url


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss: Boss) -> None:
    """/work/image.png → macOS: open; Linux: xdg-open."""
    if len(args) != 2 or target_window_id not in boss.window_id_map:
        return

    # Bypass URL dispatch to avoid matching the image rule again.
    open_url(args[1])
