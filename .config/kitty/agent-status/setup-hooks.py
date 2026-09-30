"""Preview agent hook changes; --apply backs up and writes settings."""

from __future__ import annotations

import argparse
import ast
from copy import deepcopy
import json
import os
from pathlib import Path
import shlex
import shutil
import tempfile
from typing import TypedDict


class CommandHook(TypedDict):
    type: str
    command: str
    timeout: int


class HookGroup(TypedDict, total=False):
    matcher: str
    hooks: list[CommandHook]


class Settings(TypedDict, total=False):
    hooks: dict[str, list[HookGroup]]


EVENTS = ('SessionStart', 'SessionEnd', 'UserPromptSubmit', 'PreToolUse',
          'PermissionRequest', 'PostToolUse', 'PreCompact', 'PostCompact', 'Stop')
BRIDGE = Path(__file__).resolve().with_name('agent_status.py')


def is_agent_hook(command: object, agent: str) -> bool:
    """Recognize 'kitty +runpy <our bridge> claude' across installation paths."""
    if not isinstance(command, str):
        return False
    try:
        args = shlex.split(command)
        if len(args) != 4 or Path(args[0]).name != 'kitty' or args[1] != '+runpy' or args[3] != agent:
            return False
        prefix, suffix = 'import runpy; runpy.run_path(', ', run_name="__main__")'
        if not args[2].startswith(prefix) or not args[2].endswith(suffix):
            return False
        path = ast.literal_eval(args[2][len(prefix):-len(suffix)])
    except (ValueError, SyntaxError):
        return False
    if not isinstance(path, str):
        return False
    parts = Path(path).parts
    return parts[-2:] == ('agent-status', 'agent_status.py') or parts[-3:] == ('.config', 'kitty', 'agent_status.py')


def merge_hooks(settings: Settings, agent: str, command: str, remove: bool = False) -> Settings:
    """Old bridge paths -> updated hooks (or none with remove=True); keep other handlers."""
    result = deepcopy(settings)
    hooks = result.get('hooks', {}) if remove else result.setdefault('hooks', {})
    if not isinstance(hooks, dict):
        raise ValueError('hooks must be an object')
    events = EVENTS + (('Interrupt',) if agent == 'codex' else ('Notification', 'PostToolUseFailure', 'StopFailure'))
    for event in events:
        groups = hooks.get(event, []) if remove else hooks.setdefault(event, [])
        if not isinstance(groups, list) or any(not isinstance(g, dict) or not isinstance(g.get('hooks'), list) for g in groups):
            raise ValueError(f'Invalid hook groups for {event}')
        handlers = [handler for group in groups for handler in group['hooks']]
        if any(not isinstance(handler, dict) for handler in handlers):
            raise ValueError(f'Invalid hook handler for {event}')
        installed = [(group, handler) for group in groups if not group.get('matcher') for handler in group['hooks']
                     if handler.get('type') == 'command'
                     and (handler.get('command') == command or is_agent_hook(handler.get('command'), agent))]
        if installed:
            if not remove:
                installed[0][1]['command'] = command
            for group, handler in installed if remove else installed[1:]:
                group['hooks'].remove(handler)
                if not group['hooks']:
                    groups.remove(group)
            if not groups:
                hooks.pop(event, None)
            continue
        if not remove:
            groups.append(HookGroup(hooks=[CommandHook(type='command', command=command, timeout=3)]))
    if remove and settings.get('hooks') and not hooks:
        result.pop('hooks')
    return result


def write_settings(path: Path, settings: Settings) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        with tempfile.NamedTemporaryFile(prefix=path.name + '.kitty-backup-', dir=path.parent, delete=False) as backup:
            shutil.copyfile(path, backup.name)
        print(f'Backup: {backup.name}')
    with tempfile.NamedTemporaryFile(mode='w', prefix=path.name + '.', dir=path.parent, delete=False) as output:
        temporary = Path(output.name)
        json.dump(settings, output, indent=2, ensure_ascii=False)
        output.write('\n')
    try:
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--remove', action='store_true', help='remove only this plugin\'s hooks')
    parser.add_argument('--codex-dir', type=Path, default=Path(os.environ.get('CODEX_HOME') or Path.home() / '.codex'))
    parser.add_argument('--claude-dir', type=Path, default=Path(os.environ.get('CLAUDE_CONFIG_DIR') or Path.home() / '.claude'))
    args = parser.parse_args()
    kitty = shutil.which('kitty')
    if not kitty and not args.remove:
        parser.error('kitty must be installed and available on PATH')
    code = f'import runpy; runpy.run_path({str(BRIDGE)!r}, run_name="__main__")'
    updates = []
    for agent, path in (('codex', args.codex_dir / 'hooks.json'), ('claude', args.claude_dir / 'settings.json')):
        current = json.loads(path.read_text()) if path.exists() else {}
        if not isinstance(current, dict):
            parser.error(f'{path} must contain a JSON object')
        command = shlex.join([kitty or 'kitty', '+runpy', code, agent])
        merged = merge_hooks(current, agent, command, remove=args.remove)
        if merged != current:
            updates.append((path, merged))
            detail = 'Remove agent-status hooks' if args.remove else command
            print(f'{agent}: {path}\n  {detail}')
    if not updates:
        print('No agent-status hooks to remove.' if args.remove else 'Agent hooks are already installed.')
        return
    if not args.apply:
        print('Preview only. Add --apply to back up and write these changes.')
        return
    for path, merged in updates:
        write_settings(path, merged)
    print('Removed. Restart the agents.' if args.remove else
          'Installed. Restart the agents; review and trust the new hooks with /hooks in Codex.')


if __name__ == '__main__':
    main()
