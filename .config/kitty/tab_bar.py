"""kitty also loads tab_bar.py for native tab titles; stay inert when disabled."""

import runpy
from pathlib import Path

from kitty.fast_data_types import get_options

if get_options().env.get('KITTY_AGENT_STATUS') == '1':
    globals().update(runpy.run_path(str(Path(__file__).resolve().parent / 'agent-status' / 'renderer.py')))
