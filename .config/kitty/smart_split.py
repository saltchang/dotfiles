from kittens.tui.handler import result_handler
from kitty.boss import Boss


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss: Boss) -> None:
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    geometry = window.geometry
    width = geometry.right - geometry.left
    height = geometry.bottom - geometry.top
    # ponytail: fixed readability threshold; make configurable if displays need different ratios.
    location = "vsplit" if width >= 1.5 * height else "hsplit"
    boss.launch(f"--location={location}", "--cwd=current")
