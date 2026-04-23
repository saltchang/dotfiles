from kitty.boss import Boss
from kittens.tui.handler import result_handler


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss: Boss) -> None:
    direction = next((a for a in args if a in ('left', 'right')), None)
    if direction is None:
        return

    tab = boss.active_tab
    if tab is None:
        return

    active = tab.active_window
    if active is None:
        return
    before_id = active.id

    tab.neighboring_window(direction)

    after = tab.active_window
    if after is not None and after.id != before_id:
        return

    if direction == 'left':
        boss.previous_tab()
    else:
        boss.next_tab()
