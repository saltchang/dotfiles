"""Run with uv; delegate to kitty's Python to exercise its actual Screen API."""

from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import pty
import re
import select
import shlex
import shutil
import subprocess
import sys
import tempfile
import time
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parents[1]
PLUGIN = ROOT / '.config/kitty/agent-status'
sys.path.insert(0, str(PLUGIN))

import agent_status as status

spec = importlib.util.spec_from_file_location('setup_agents', PLUGIN / 'setup-hooks.py')
setup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup)


def event(name: str, window_id: int = 1, **fields) -> status.AgentEvent:
    payload = status.HookInput(hook_event_name=name, session_id='main', transcript_path='/main.jsonl', **fields)
    return status.normalize_hook('codex', payload, os.getpid(), window_id)


def make_window(window_id: int, state: status.AgentState | None = None, agent: str = '', text: str = ''):
    from kitty.fast_data_types import Screen
    screen = Screen(None, 12, 80)
    screen.draw(text.replace('\n', '\r\n'))
    if state and state['status'] != 'exited':
        agent = state['agent']
    window = SimpleNamespace(
        id=window_id, user_vars={status.STATE_VAR: json.dumps(state)} if state else {}, screen=screen,
        child=SimpleNamespace(foreground_processes=[{'pid': window_id * 10, 'cmdline': [agent]}] if agent else []),
        tabref=Mock(return_value=SimpleNamespace(mark_tab_bar_dirty=Mock())),
    )
    def set_var(key, value):
        if value is None:
            window.user_vars.pop(key, None)
        else:
            window.user_vars[key] = value
    window.set_user_var = set_var
    return window


class AgentTests(unittest.TestCase):
    def test_packaged_config_is_independent_and_can_be_disabled_on_startup(self):
        from kitty.constants import kitty_exe
        package = ROOT / '.config/kitty/agent-status'
        self.assertTrue(package.is_dir())
        with tempfile.TemporaryDirectory(prefix='kitty package ') as directory:
            config = Path(directory)
            shutil.copytree(package, config / 'agent-status', ignore=shutil.ignore_patterns('__pycache__'))
            shutil.copy2(ROOT / '.config/kitty/tab_bar.py', config / 'tab_bar.py')
            for enabled in (False, True):
                (config / 'kitty.conf').write_text('tab_bar_style powerline\n' + (
                    'include agent-status/agent-status.conf\n' if enabled else ''
                ))
                code = f'''
import runpy
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch
from kitty.config import load_config
from kitty.fast_data_types import set_options
from kitty import tab_bar
from kittens.runner import create_kitten_handler
check = unittest.TestCase()
config = Path({directory!r})
enabled = {enabled!r}
options = load_config(str(config / 'kitty.conf'))
set_options(options, False)
check.assertEqual(options.env.get('KITTY_AGENT_STATUS') == '1', enabled)
check.assertEqual(options.tab_bar_style, 'custom' if enabled else 'powerline')
check.assertEqual(bool(options.watcher), enabled)
original = tab_bar.TabBar.layout
boss = SimpleNamespace(window_id_map={{}})
with patch('kitty.fast_data_types.get_boss', return_value=boss), patch('kitty.fast_data_types.add_timer') as timer:
    tab_bar.load_custom_draw_title({{}})
    check.assertEqual(timer.call_count, int(enabled))
    check.assertEqual('agent_status' in sys.modules, enabled)
    if enabled:
        check.assertIsNot(tab_bar.TabBar.layout, original)
        check.assertTrue(tab_bar.load_custom_draw_tab().agent_multiline)
        handler = create_kitten_handler('agent-status/agent_picker.py', [])
        check.assertTrue(handler.allow_remote_control)
        setup = runpy.run_path(str(config / 'agent-status/setup-hooks.py'))
        check.assertEqual(setup['BRIDGE'], (config / 'agent-status/agent_status.py').resolve())
    else:
        check.assertIs(tab_bar.TabBar.layout, original)
print('enabled' if enabled else 'disabled')
'''
                result = subprocess.run([kitty_exe(), '+runpy', f'exec({code!r}, {{}})'],
                                        env={**os.environ, 'KITTY_CONFIG_DIRECTORY': directory},
                                        capture_output=True, text=True, timeout=10)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(result.stdout.strip(), 'enabled' if enabled else 'disabled')

    def test_agent_detection_distinguishes_executables_from_arguments(self):
        cases = (
            ([], ''),
            (['/usr/bin/vim', 'claude'], ''),
            (['/usr/bin/less', '/tmp/codex'], ''),
            (['/usr/bin/rg', 'codex'], ''),
            (['node', '--eval', 'claude'], ''),
            (['/usr/bin/python3', '/tmp/codex'], ''),
            (['/opt/bin/codex', 'resume'], 'codex'),
            (['/opt/bin/claude', '--resume'], 'claude'),
            (['/usr/bin/node', '/opt/bin/codex.js'], 'codex'),
            (['nodejs', '/opt/bin/claude.js'], 'claude'),
            (['bun', '/opt/bin/claude'], 'claude'),
        )
        for command, agent in cases:
            with self.subTest(command=command):
                window = make_window(42)
                window.child.foreground_processes = [{'pid': 420, 'cmdline': command}]
                self.assertEqual(status.window_status(window), (agent, 'unknown' if agent else 'shell'))

    def test_existing_agent_window_is_detected_without_hooks(self):
        import renderer as tab_bar
        for width in (80, 20):
            window = make_window(42, agent='codex', text='• Working (12s • esc to interrupt)\n\n› \n  ? for shortcuts')
            window.screen.resize(12, width)
            boss = SimpleNamespace(tab_for_id=lambda tab_id: [window])
            with self.subTest(width=width), patch.object(tab_bar, 'get_boss', return_value=boss):
                self.assertEqual(tab_bar.window_states(1)[0][1:], ('codex', 'working'))

    def test_screen_controls_distinguish_working_questions_and_idle(self):
        cases = (
            ('codex', '• Working (12s • esc to interrupt)\n› ', 'unknown', 'working'),
            ('claude', '✻ Thinking… (esc to interrupt)\n────────\n❯ \n────────', 'unknown', 'working'),
            ('claude', '✽ Frolicking… (1s · thinking with xhigh effort)\n────────\n❯ ', 'waiting', 'working'),
            ('codex', 'Would you like to run the following command?\n› 1. Yes\n  2. No\nPress enter to confirm or esc to cancel', 'working', 'waiting'),
            ('codex', 'Question 1/1\nWhat should we name it?\n› \nSubmit with ctrl+enter', 'working', 'waiting'),
            ('claude', 'Do you want to proceed?\n❯ 1. Yes\n  2. No\nEsc to cancel · Tab to amend', 'working', 'waiting'),
            ('claude', 'Question\n❯ 1. Option A\n  2. Option B\nEnter to select · ↑/↓ to navigate · Esc to cancel', 'unknown', 'waiting'),
            ('codex', '› ', 'unknown', 'idle'),
            ('codex', '• Answer\n› ', 'working', 'done'),
            ('claude', '● Answer\n❯ ', 'working', 'done'),
            ('codex', '› ', 'waiting', 'done'),
            ('codex', '■ Conversation interrupted - tell the model what to do differently\n› ', 'working', 'idle'),
            ('claude', '⎿ Interrupted · What should Claude do instead?\n❯ ', 'working', 'idle'),
            ('codex', '■ Conversation interrupted - tell the model what to do differently\n› ', 'error', 'idle'),
            ('codex', '› ', 'idle', 'idle'),
            ('codex', '■ Conversation interrupted\n• Working (1s • esc to interrupt)\n› ', 'idle', 'working'),
            ('claude', '⎿ Interrupted\n✻ Thinking… (esc to interrupt)\n❯ ', 'idle', 'working'),
            ('codex', '› explain the phrase esc to interrupt', 'unknown', 'idle'),
            ('codex', '• The shortcut esc to interrupt stops a task.\n› ', 'working', 'done'),
            ('claude', '● Example:\n❯ 1. sample\nmore explanation\n❯ ', 'working', 'done'),
            ('codex', 'unknown UI', 'unknown', ''),
        )
        for agent, text, previous, expected in cases:
            with self.subTest(agent=agent, text=text):
                self.assertEqual(status.screen_status(agent, text, previous), expected)

    def test_claude_spinner_without_interrupt_hint_reaches_completion(self):
        # Captured from Claude Code 2.1.246 with a custom status line.
        prompt = ('\n\n────────────────────\n❯\u00a0\n────────────────────\n'
                  '  [Opus 5 | Vertex] │ project git:(main)\n'
                  '  Context █░░░░░░░░░ 14%\n'
                  '  ⏵⏵ bypass permissions on (shift+tab to cycle) · ← for agents')
        for width in (105, 40):
            with self.subTest(width=width):
                window = make_window(133, agent='claude')
                window.screen.resize(24, width)
                for body, expected in (
                    ('✻ Worked for 6s · done 6:19 PM', 'idle'),
                    ('✢ Frolicking… ', 'working'),
                    ('✽ Frolicking… (1s · thinking with xhigh effort)', 'working'),
                    ('⏺\n\n✶ Frolicking… (2s · ↓ 50 tokens · thinking with xhigh effort)', 'working'),
                    ('✻ Frolicking… (3s · ↓ 172 tokens · thought for 1s)', 'working'),
                    ('✻ Cooked for 4s · done 6:19 PM', 'done'),
                    ('✻ Crafting… ', 'working'),
                    ('✻ Sautéed for 15s · done 6:20 PM', 'done'),
                ):
                    window.screen.reset()
                    window.screen.draw((body + prompt).replace('\n', '\r\n'))
                    self.assertEqual(status.window_status(window), ('claude', expected), body)

    def test_claude_api_failure_without_hooks_is_not_completion(self):
        # Claude Code 2.1.246 displays a completion banner even after this 401.
        prompt = ('\n\n\n\n\n\n────────\n❯ \n────────\n'
                  '  [Opus 5 | Vertex] │ project git:(main)\n'
                  '  Context ░░░░░░░░░░ 0%\n'
                  '  ⏵⏵ bypass permissions on (shift+tab to cycle) · ← for agents')
        failure = ('❯ hi\n\n⏺ Please run /login · API Error: 401 status code (no body)\n\n'
                   '✻ Brewed for 5s · done 6:32 PM')
        working = '\n✻ Thinking…\n────────\n❯ \n────────'
        for width in (105, 40):
            window = make_window(188, agent='claude')
            window.screen.resize(32, width)
            for text, expected in (
                (working, 'working'),
                (failure + prompt, 'error'),
                (failure + prompt, 'error'),
                (failure + working, 'working'),
                (failure + '\n⏺ Hello!' + prompt, 'done'),
                ('⏺ Bash(curl example.test)\n  ⎿ API Error: 401' + prompt, 'done'),
                ('⏺ The server returned API Error: 401 in the example.' + prompt, 'done'),
                ('⏺ API Error: 429 rate limit exceeded' + prompt, 'error'),
                ('⎿ Interrupted · What should Claude do instead?\n❯ ', 'idle'),
            ):
                with self.subTest(width=width, expected=expected, text=text):
                    window.screen.reset()
                    window.screen.draw(text.replace('\n', '\r\n'))
                    self.assertEqual(status.window_status(window), ('claude', expected))

    def test_codex_terminal_errors_are_distinct_from_retries_and_interruptions(self):
        # Error/retry wording from Codex 0.158.0; tool output is indented.
        prompt = '\n\n› \n\n  project · main\n  ? for shortcuts'
        failure = '■ unexpected status 401 Unauthorized: Incorrect API key provided'
        # Captured while the failure-test session waits for network indefinitely.
        reconnecting = ('• Reconnecting... waiting for network (1m 41s • esc to interrupt)\n'
                        '  └ Connection failed: error sending request\n'
                        '  └ Tip: Switch models or reasoning effort quickly with /model.')
        for width in (104, 40):
            window = make_window(134, agent='codex')
            window.screen.resize(24, width)
            for body, expected in (
                (failure, 'error'),
                (failure, 'error'),
                (failure + '\n\n• Reconnecting... 1/5', 'reconnecting'),
                ('■ stream disconnected before completion: error sending request for url (http://127.0.0.1:1/v1/responses)', 'error'),
                ('• Reconnecting... waiting for network', 'reconnecting'),
                (reconnecting, 'reconnecting'),
                (reconnecting, 'reconnecting'),
                (reconnecting + '\n\n• Working (1s • esc to interrupt)', 'working'),
                (reconnecting, 'reconnecting'),
                (reconnecting + '\n\n• Hello!', 'done'),
                ('• Reconnecting… 2/5', 'reconnecting'),
                ('', 'done'),
                (reconnecting, 'reconnecting'),
                ('■ exceeded retry limit, last status: 503 Service Unavailable', 'error'),
                ('■ You’ve hit your usage limit. Try again later.', 'error'),
                (failure + '\n\n• Working (1s • esc to interrupt)', 'working'),
                (failure + '\n\n• The task is complete.', 'done'),
                ('• Ran a command\n  └ Process exited with code 1\n    ■ unexpected status 401 Unauthorized', 'done'),
                ('• Example error output:\n  ■ stream disconnected before completion', 'done'),
                ('• Example retry output:\n  • Reconnecting... waiting for network', 'done'),
                (reconnecting, 'reconnecting'),
                (reconnecting + '\n\n■ Conversation interrupted - tell the model what to do differently.', 'idle'),
                (failure + '\n\n■ Conversation interrupted - tell the model what to do differently.', 'idle'),
                ('■ Goal budget reached - the turn was stopped.', 'idle'),
                ('• Working (1s • esc to interrupt)', 'working'),
                ('■ Error while reading the server response: connection reset', 'error'),
                ('■ Your access token could not be refreshed. Please log out and sign in again.', 'error'),
            ):
                with self.subTest(width=width, expected=expected, body=body):
                    window.screen.reset()
                    window.screen.draw((body + prompt).replace('\n', '\r\n'))
                    self.assertEqual(status.window_status(window), ('codex', expected))
            # A late completion hook must not hide a terminal failure still on screen.
            status.on_set_user_var(None, window, {'key': status.EVENT_VAR, 'value': json.dumps(event('Stop', 134))})
            self.assertEqual(status.window_status(window), ('codex', 'error'))

    def test_codex_async_question_screen_lifecycle(self):
        # Captured from Codex 0.158: the question is initially outside the input box.
        working = '• Working (2m 46s • esc to interrupt)\n \n'
        reconnecting = '• Reconnecting... waiting for network (1m 41s • esc to interrupt)\n \n'
        prompt = '\n \n› Ask Codex to do anything\n \n  dotfiles · main\n  ← for agents · ? for shortcuts'
        pending = '• Queued follow-up inputs\n  ? 1 question · 7s\n    shift+← to answer\n '
        selected = ('• Queued follow-up inputs\n \n  目前顯示什麼狀態？\n \n'
                    '  › 1. Turn completed\n    2. Waiting for input\n    3. Working\n    4. Other\n \n'
                    '  enter submit   ctrl+] skip   shift+→ main prompt')
        submitted = ('• Messages to be submitted after next tool call (press esc to interrupt and send immediately)\n'
                     '  ↳ > 目前顯示什麼狀態？\n \n    Turn completed\n ')
        for width in (104, 40):
            window = make_window(134, status.transition(None, event('Stop', 134)))
            window.screen.resize(24, width)
            for text, expected in (
                (working + pending + prompt, 'waiting'),
                (reconnecting + pending + prompt, 'waiting'),
                (pending + prompt, 'waiting'),
                (working + selected, 'waiting'),
                (working + submitted + prompt, 'working'),
                (working + prompt, 'working'),
                (pending + prompt, 'waiting'),
                (prompt, 'done'),
                (pending + prompt + '\n• Answer\n' + prompt, 'done'),
            ):
                with self.subTest(width=width, expected=expected, text=text):
                    window.screen.reset()
                    window.screen.draw(text.replace('\n', '\r\n'))
                    self.assertEqual(status.window_status(window), ('codex', expected))

    def test_completed_turn_tracks_live_background_shells_until_they_exit(self):
        # Live controls captured after Codex 0.158.0 / Claude 2.1.246 ended a turn.
        codex_prompt = '\n\n› Ask Codex to do anything\n\n  project · main\n  ? for shortcuts'
        codex_background = '\n  1 background terminal running · /ps to view · /stop to close'
        claude_prompt = ('\n\n────────\n❯\u00a0\n────────\n'
                         '  [Opus 5 | Vertex] │ project\n  Context ░░░░░░░░░░ 14%\n'
                         '  ⏵⏵ bypass permissions on{shells} · ← for agents')
        claude_body = ('⏺ Started the background command.\n\n'
                       '✻ Cogitated for 4s · done 10:50 AM · 1 shell still running')
        for agent, running, completed, working, failed in (
            ('codex', '• Started.' + codex_background + codex_prompt, '• Finished.' + codex_prompt,
             '• Working (12s • esc to interrupt) · 1 background terminal running · /ps to view · /stop to close' + codex_prompt,
             '■ unexpected status 401 Unauthorized' + codex_background + codex_prompt),
            ('claude', claude_body + claude_prompt.format(shells=' · 1 shell'),
             claude_body + claude_prompt.format(shells=''),
             '✻ Thinking…' + claude_prompt.format(shells=' · 1 shell'),
             '⏺ API Error: 401' + claude_prompt.format(shells=' · 1 shell')),
        ):
            for width in (104, 40):
                window = make_window(42, agent=agent)
                window.screen.resize(30, width)
                for text, expected in (
                    (running, 'background'),
                    (running, 'background'),
                    (working, 'working'),
                    (running, 'background'),
                    (running.replace('1 background terminal', '2 background terminals').replace('1 shell ·', '2 shells ·'), 'background'),
                    (completed, 'done'),
                    (completed, 'done'),
                    (running, 'background'),
                    (running.replace('1 background terminal', '0 background terminals').replace('1 shell ·', '0 shells ·'), 'done'),
                    (failed, 'error'),
                ):
                    with self.subTest(agent=agent, width=width, expected=expected, text=text):
                        window.screen.reset()
                        window.screen.draw(text.replace('\n', '\r\n'))
                        self.assertEqual(status.window_status(window), (agent, expected))
                # A Stop hook can arrive after the screen has already shown the background work.
                window.screen.reset()
                window.screen.draw(running.replace('\n', '\r\n'))
                stopped = status.normalize_hook(agent, status.HookInput(hook_event_name='Stop', session_id='main'), os.getpid(), 42)
                status.on_set_user_var(None, window, {'key': status.EVENT_VAR, 'value': json.dumps(stopped)})
                self.assertEqual(status.window_status(window), (agent, 'background'))

        for agent, text in (
            ('codex', '• Example: 1 background terminal running · /ps to view · /stop to close' + codex_prompt),
            ('claude', claude_body + claude_prompt.format(shells='')),
            ('claude', '⏺ The footer says 1 shell.' + claude_prompt.format(shells='')),
        ):
            self.assertEqual(status.screen_status(agent, text, 'done'), 'done')
        self.assertEqual(status.screen_status('codex', 'Question 1/1\nName?\n› \nSubmit with ctrl+enter' + codex_background, 'background'), 'waiting')
        self.assertEqual(status.screen_status('claude', 'Proceed?\n❯ 1. Yes\n  2. No\nEnter to confirm · Esc to cancel · 1 shell', 'background'), 'waiting')

    def test_stop_hook_reports_background_shells_without_counting_subagents(self):
        for task, expected in (
            ({'type': 'shell', 'status': 'running'}, 'background'),
            ({'type': 'subagent', 'status': 'running'}, 'done'),
            ({'type': 'shell', 'status': 'completed'}, 'done'),
        ):
            payload = status.HookInput(hook_event_name='Stop', session_id='main', background_tasks=[task])
            stopped = status.normalize_hook('claude', payload, os.getpid(), 42)
            state = status.transition(None, stopped)
            self.assertEqual(state['status'], expected)
            if expected == 'background':
                for name in ('PostToolUse', 'Notification'):
                    late = status.normalize_hook('claude', status.HookInput(
                        hook_event_name=name, session_id='main', notification_type='idle_prompt', tool_name='Bash',
                    ), os.getpid(), 42)
                    self.assertEqual(status.transition(state, late), state)

    def test_polling_updates_background_windows_and_discards_exited_processes(self):
        from agent_picker import rows_for_windows
        first = make_window(41, agent='codex', text='• Working (12s • esc to interrupt)\n› ')
        second = make_window(42, agent='claude', text='Do you want to proceed?\n❯ 1. Yes\n  2. No\nEsc to cancel · Tab to amend')
        overlay = SimpleNamespace(user_vars={status.PICKER_VAR: '1'})
        boss = SimpleNamespace(window_id_map={41: first, 42: second, 43: overlay})
        status.poll_windows(boss)
        for window, expected in ((first, 'working'), (second, 'waiting')):
            self.assertEqual(json.loads(window.user_vars[status.STATE_VAR])['status'], expected)
            window.tabref().mark_tab_bar_dirty.assert_called_once()
        status.poll_windows(boss)
        self.assertEqual(first.tabref().mark_tab_bar_dirty.call_count, 2)
        first.screen.reset()
        first.screen.draw('• Answer\r\n› ')
        status.poll_windows(boss)
        self.assertEqual(json.loads(first.user_vars[status.STATE_VAR])['status'], 'done')
        rows = rows_for_windows([{'id': 1, 'tabs': [{'id': 1, 'title': 'Background', 'windows': [
            {'id': first.id, 'title': '', 'user_vars': first.user_vars, 'foreground_processes': first.child.foreground_processes},
        ]}]}], os.getpid())
        self.assertEqual(rows[0]['status'], 'done')
        # A hook can take over a session that was first found by screen polling.
        status.on_set_user_var(boss, first, {'key': status.EVENT_VAR, 'value': json.dumps(event('PermissionRequest', 41))})
        self.assertEqual(json.loads(first.user_vars[status.STATE_VAR])['status'], 'waiting')
        status.poll_windows(boss)
        first.child.foreground_processes[0]['pid'] += 1
        status.poll_windows(boss)
        self.assertEqual(json.loads(first.user_vars[status.STATE_VAR])['status'], 'idle')
        first.child.foreground_processes.clear()
        status.poll_windows(boss)
        self.assertNotIn(status.STATE_VAR, first.user_vars)

    def test_monitor_reload_keeps_one_timer_and_attaches_watchers_once(self):
        from kitty.window import Watchers
        window = make_window(42, agent='codex', text='› ')
        window.watchers = Watchers()
        boss = SimpleNamespace(window_id_map={42: window})
        after_poll = Mock()
        with patch('kitty.fast_data_types.get_boss', return_value=boss), \
             patch('kitty.fast_data_types.add_timer', side_effect=[21, 22]) as add, \
             patch('kitty.fast_data_types.remove_timer') as remove:
            status.start_monitor(after_poll)
            status.start_monitor(after_poll)
            remove.assert_called_once_with(21)
            self.assertEqual(boss._agent_status_timer, 22)
            callback, delay, repeat = add.call_args.args
            self.assertEqual((delay, repeat), (0.2, True))
            callback(22)
            after_poll.assert_called_once_with()
        self.assertEqual(len(window.watchers.on_set_user_var), 1)
        self.assertEqual(len(window.watchers.on_cmd_startstop), 1)
        window.watchers.on_set_user_var[0](boss, window, {
            'key': status.EVENT_VAR, 'value': json.dumps(event('PermissionRequest', 42)),
        })
        self.assertEqual(json.loads(window.user_vars[status.STATE_VAR])['status'], 'waiting')

    def test_status_animation_repaints_without_changing_state_or_width(self):
        from kitty.fast_data_types import Screen, wcswidth
        from kitty.tab_bar import as_rgb
        import renderer as tab_bar
        cases = (
            ('working', 'Working', '·', '✳', 0x77DBF4),
            ('background', 'Background running', '□', '■', 0x8BE9FD),
            ('reconnecting', 'Reconnecting', '◐', '◑', 0xFFB86C),
            ('waiting', 'Action Required', '!', ' ', 0xBD93F9),
            ('error', 'Failed', '×', ' ', 0xFF4444),
            ('done', 'Turn completed', '✓', '✓', 0x69F197),
            ('idle', 'Waiting for task', '○', '○', 0xC6E8F1),
        )
        for state_name, label, first_icon, next_icon, color in cases:
            self.assertEqual({(len(frame), wcswidth(frame)) for frame in status.LABELS[state_name][0]}, {(1, 1)})
            window = make_window(42, status.transition(None, event('SessionStart', 42)))
            state = json.loads(window.user_vars[status.STATE_VAR])
            state.update(status=state_name, agent_pid=420)
            window.user_vars[status.STATE_VAR] = json.dumps(state)
            boss = SimpleNamespace(window_id_map={42: window})
            widths = []
            for now, icon in ((0.0, first_icon), (0.4, next_icon)):
                with self.subTest(state=state_name, time=now), patch('agent_status.time.monotonic', return_value=now):
                    text = status.status_text('codex', state_name)
                    self.assertEqual(text, f'{icon} Codex: {label}')
                    widths.append(wcswidth(text))
                    for active in (False, True):
                        label_text = status.status_text('codex', state_name, active)
                        self.assertEqual(label_text, ('➤ ' if active else '') + text)
                        screen = Screen(None, 1, 50)
                        tab_bar.draw_agent_label(screen, label_text, state_name, active)
                        self.assertEqual(str(screen.line(0)), label_text.rstrip())
                        for column in range(wcswidth(label_text)):
                            cursor = screen.line(0).cursor_from(column)
                            if active or state_name != 'working':
                                self.assertEqual(cursor.fg, as_rgb(0xFFFF55 if active else color))
                            self.assertEqual(cursor.bold, active)
                    status.poll_windows(boss)
                    self.assertEqual(json.loads(window.user_vars[status.STATE_VAR]), state)
            self.assertEqual(widths[0], widths[1])
            self.assertEqual(window.tabref().mark_tab_bar_dirty.call_count, 2 if first_icon != next_icon else 0)

    def test_working_color_wave_moves_right_without_moving_text(self):
        from kitty.fast_data_types import Screen, wcswidth
        import renderer as tab_bar
        text = '✻ Codex: Working'
        width = wcswidth(text)
        frames = []
        for now in (0.0, 0.5):
            screen = Screen(None, 1, width + 8)
            screen.cursor.x = 3
            with patch('agent_status.time.monotonic', return_value=now):
                tab_bar.draw_agent_label(screen, text, 'working', False)
            self.assertEqual(str(screen.line(0)), '   ' + text)
            self.assertEqual((screen.cursor.x, screen.cursor.y), (width + 3, 0))
            colors = [screen.line(0).cursor_from(x).fg for x in range(3, width + 3)]
            self.assertGreater(len(set(colors)), 3)
            frames.append(colors)
        self.assertNotEqual(frames[0], frames[1])
        self.assertEqual(frames[1][2:], frames[0][:-2])

    def test_wait_survives_unrelated_tools_and_clears_after_answer(self):
        state = status.transition(None, event('UserPromptSubmit'))
        state = status.transition(state, event('PreToolUse', tool_name='request_user_input'))
        self.assertEqual(state['status'], 'waiting')
        for name in ('PreToolUse', 'PostToolUse'):
            state = status.transition(state, event(name, tool_name='Bash'))
            self.assertEqual(state['status'], 'waiting')
        state = status.transition(state, event('PostToolUse', tool_name='request_user_input'))
        self.assertEqual(state['status'], 'working')
        self.assertEqual(status.transition(state, event('Stop'))['status'], 'done')

    def test_unanswered_async_question_survives_turn_completion(self):
        question = status.transition(None, event('PreToolUse', tool_name='functions.request_user_input_async'))
        for name in ('PostToolUse', 'Stop'):
            question = status.transition(question, event(name, tool_name='functions.request_user_input_async'))
            self.assertEqual(question['status'], 'waiting')
        answered = status.transition(question, event('UserPromptSubmit'))
        self.assertEqual(answered['status'], 'working')
        self.assertEqual(status.transition(answered, event('Stop'))['status'], 'done')
        failed = status.transition(question, event('PostToolUseFailure', tool_name='functions.request_user_input_async'))
        self.assertEqual(failed['status'], 'working')

    def test_permission_failure_releases_wait_and_interrupt_is_not_done(self):
        state = status.transition(None, event('PermissionRequest', tool_name='Bash'))
        self.assertEqual(state['status'], 'waiting')
        self.assertEqual(status.transition(state, event('PostToolUseFailure', tool_name='Bash'))['status'], 'working')
        self.assertEqual(status.transition(state, event('Interrupt'))['status'], 'idle')
        self.assertEqual(status.transition(state, event('SessionEnd'))['status'], 'exited')

    def test_stop_failure_survives_polling_until_work_resumes(self):
        window = make_window(42, agent='claude', text='❯ ')
        failure = status.normalize_hook(
            'claude', status.HookInput(hook_event_name='StopFailure', session_id='main'), os.getpid(), window.id,
        )
        status.on_set_user_var(None, window, {'key': status.EVENT_VAR, 'value': json.dumps(failure)})
        for _ in range(2):
            self.assertEqual(status.window_status(window), ('claude', 'error'))
        notification = status.normalize_hook(
            'claude', status.HookInput(hook_event_name='Notification', session_id='main', notification_type='idle_prompt'),
            os.getpid(), window.id,
        )
        status.on_set_user_var(None, window, {'key': status.EVENT_VAR, 'value': json.dumps(notification)})
        self.assertEqual(status.window_status(window), ('claude', 'error'))
        window.screen.reset()
        window.screen.draw('✻ Thinking… (esc to interrupt)\r\n❯ ')
        self.assertEqual(status.window_status(window), ('claude', 'working'))

    def test_subagents_and_old_sessions_do_not_finish_parent(self):
        self.assertIsNone(status.normalize_hook('claude', {'session_id': 'main', 'agent_id': 'child'}, 1, 1))
        state = status.transition(None, event('UserPromptSubmit'))
        child = event('Stop')
        child['transcript'] = '/subagent.jsonl'
        self.assertEqual(status.transition(state, child), state)
        old = event('SessionEnd')
        old['session'] = 'old'
        self.assertEqual(status.transition(state, old), state)

    def test_notifications_and_compaction(self):
        state = status.transition(None, event('Notification', notification_type='permission_prompt'))
        self.assertEqual(state['status'], 'waiting')
        self.assertEqual(status.transition(state, event('Notification', notification_type='auth_success')), state)
        self.assertEqual(status.transition(state, event('Notification', notification_type='idle_prompt'))['status'], 'done')
        self.assertEqual(status.transition(None, event('SessionStart', source='compact'))['status'], 'working')

    def test_late_hooks_do_not_revert_a_newer_lifecycle_state(self):
        working = status.transition(None, event('UserPromptSubmit'))
        self.assertEqual(status.transition(working, event('SessionStart', source='startup')), working)
        self.assertEqual(status.transition(working, event('Notification', notification_type='idle_prompt')), working)
        reconnecting = working.copy()
        reconnecting['status'] = 'reconnecting'
        self.assertEqual(status.transition(reconnecting, event('Notification', notification_type='idle_prompt')), reconnecting)
        done = status.transition(working, event('Stop'))
        self.assertEqual(status.transition(done, event('PostToolUse', tool_name='Bash')), done)

    def test_invalid_and_restored_state_is_ignored(self):
        state = status.transition(None, event('Stop'))
        self.assertEqual(status.read_state(json.dumps(state), os.getpid(), 1), state)
        self.assertIsNone(status.read_state(json.dumps(state), os.getpid() + 1, 1))
        self.assertIsNone(status.read_state(json.dumps(state), os.getpid(), 2))
        for raw in ('[]', '{}', 'garbage', 'null'):
            self.assertIsNone(status.read_state(raw, os.getpid(), 1))
        self.assertIsNone(status.normalize_hook('codex', [], 1, 1))
        self.assertIsNone(status.normalize_hook('codex', {'session_id': 'main', 'tool_name': []}, 1, 1))

    def test_watcher_isolates_panes_and_cleans_up_on_shell_return(self):
        first, second = make_window(1), make_window(2)
        status.on_set_user_var(None, first, {'key': status.EVENT_VAR, 'value': json.dumps(event('Stop'))})
        status.on_set_user_var(None, second, {'key': status.EVENT_VAR, 'value': json.dumps(event('PermissionRequest', 2))})
        status.on_set_user_var(None, second, {'key': status.EVENT_VAR, 'value': json.dumps(event('Stop'))})
        self.assertEqual(json.loads(first.user_vars[status.STATE_VAR])['status'], 'done')
        self.assertEqual(json.loads(second.user_vars[status.STATE_VAR])['status'], 'waiting')
        status.on_cmd_startstop(None, first, {'is_start': False})
        self.assertEqual(json.loads(first.user_vars[status.STATE_VAR])['status'], 'exited')
        status.on_cmd_startstop(None, first, {'is_start': True})
        self.assertNotIn(status.STATE_VAR, first.user_vars)
        self.assertEqual(first.tabref().mark_tab_bar_dirty.call_count, 3)
        second.tabref().mark_tab_bar_dirty.assert_called_once()

    def test_merge_preserves_existing_handlers_and_is_idempotent(self):
        original = {'theme': 'dark', 'hooks': {'PreToolUse': [
            {'matcher': 'Bash', 'hooks': [{'type': 'command', 'command': 'my-guard'}]},
        ], 'WorktreeCreate': [{'hooks': [{'type': 'command', 'command': 'my-worktree'}]}]}}
        merged = setup.merge_hooks(original, 'claude', 'kitty hook')
        self.assertEqual(merged['theme'], 'dark')
        self.assertEqual(merged['hooks']['PreToolUse'][0], original['hooks']['PreToolUse'][0])
        self.assertEqual(merged['hooks']['WorktreeCreate'], original['hooks']['WorktreeCreate'])
        self.assertEqual(setup.merge_hooks(merged, 'claude', 'kitty hook'), merged)
        self.assertEqual(len(original['hooks']['PreToolUse']), 1)
        with self.assertRaises(ValueError):
            setup.merge_hooks({'hooks': {'Stop': {}}}, 'codex', 'kitty hook')

    def test_hook_reinstall_updates_paths_and_removes_only_its_duplicates(self):
        commands = []
        for root, suffix in (('/old checkout', '/.config/kitty/agent_status.py'),
                             ("/another user's checkout", '/.config/kitty/agent_status.py'),
                             ('/new checkout', '/.config/kitty/agent-status/agent_status.py')):
            bridge = root + suffix
            code = f'import runpy; runpy.run_path({bridge!r}, run_name="__main__")'
            commands.append(shlex.join([root + '/kitty', '+runpy', code, 'claude']))
        old, duplicate, new = commands
        unrelated_code = 'import runpy; runpy.run_path("/other/agent_status.py", run_name="__main__")'
        unrelated = {'hooks': [
            {'type': 'command', 'command': 'echo agent_status.py'},
            {'type': 'command', 'command': 'kitty +runpy "print(1)" claude'},
            {'type': 'command', 'command': shlex.join(['kitty', '+runpy', unrelated_code, 'claude'])},
            {'type': 'command', 'command': shlex.join(shlex.split(new)[:-1] + ['codex'])},
        ]}
        original = setup.merge_hooks({'theme': 'dark', 'hooks': {'PreToolUse': [unrelated]}}, 'claude', old)
        guard = {'type': 'command', 'command': 'my-guard'}
        original['hooks']['PreToolUse'][-1]['hooks'].append(guard)
        original['hooks']['PreToolUse'].append({'hooks': [{'type': 'command', 'command': duplicate}]})
        merged = setup.merge_hooks(original, 'claude', new)
        self.assertEqual(merged['theme'], 'dark')
        self.assertEqual(merged['hooks']['PreToolUse'][0], unrelated)
        self.assertIn(guard, merged['hooks']['PreToolUse'][1]['hooks'])
        self.assertEqual(len(merged['hooks']['PreToolUse']), 2)
        for groups in merged['hooks'].values():
            installed = [handler['command'] for group in groups for handler in group['hooks']]
            self.assertEqual(installed.count(new), 1)
            self.assertNotIn(old, installed)
            self.assertNotIn(duplicate, installed)
        self.assertEqual(setup.merge_hooks(merged, 'claude', new), merged)
        self.assertIn(old, [h['command'] for h in original['hooks']['PreToolUse'][1]['hooks']])
        for installed in (original, merged):
            removed = setup.merge_hooks(installed, 'claude', new, remove=True)
            self.assertEqual(removed, {'theme': 'dark', 'hooks': {'PreToolUse': [unrelated, {'hooks': [guard]}]}})
            self.assertEqual(setup.merge_hooks(removed, 'claude', new, remove=True), removed)
        self.assertEqual(setup.merge_hooks({'theme': 'dark'}, 'claude', new, remove=True), {'theme': 'dark'})

    def test_install_backs_up_and_preserves_private_permissions(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'settings.json'
            path.write_text('{"theme":"dark"}\n')
            setup.write_settings(path, {'theme': 'light'})
            self.assertEqual(json.loads(path.read_text())['theme'], 'light')
            backups = list(path.parent.glob('settings.json.kitty-backup-*'))
            self.assertEqual(len(backups), 1)
            self.assertEqual(json.loads(backups[0].read_text())['theme'], 'dark')
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            self.assertEqual(backups[0].stat().st_mode & 0o777, 0o600)

    def test_terminal_setup_installs_hooks_and_stops_on_failure(self):
        from kitty.constants import kitty_exe
        with tempfile.TemporaryDirectory(prefix='kitty setup ') as directory:
            root = Path(directory)
            (root / '.config/kitty').mkdir(parents=True)
            (root / '.config/kitty/agent-status').symlink_to(PLUGIN, target_is_directory=True)
            (root / 'scripts').mkdir()
            (root / 'bin').mkdir()
            config_setup = root / 'scripts/setup-config-dir.sh'
            # Skip OS provisioning; keep the actual setup entry point and hook installer.
            for path, source in (
                (root / 'bin/uname', 'printf "TestOS\\n"'),
                (config_setup, 'touch config-ready'),
                (root / 'bin/kitty', 'test -f config-ready || exit 9\n'
                 f'exec {shlex.quote(kitty_exe())} "$@" '
                 f'--codex-dir {shlex.quote(str(root / "codex"))} '
                 f'--claude-dir {shlex.quote(str(root / "claude"))}'),
            ):
                path.write_text('#!/bin/bash\n' + source + '\n')
                path.chmod(0o755)
            env = {**os.environ, 'PATH': str(root / 'bin') + os.pathsep + os.environ['PATH']}
            command = ['/bin/bash', str(ROOT / 'setup-terminal.sh'), '--kitty']
            for _ in range(2):
                result = subprocess.run(command, cwd=root, env=env, capture_output=True, text=True, timeout=10)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                for path in (root / 'codex/hooks.json', root / 'claude/settings.json'):
                    groups = json.loads(path.read_text())['hooks']['Stop']
                    self.assertEqual(len(groups), 1)
                    self.assertEqual(len(groups[0]['hooks']), 1)
            self.assertFalse(list(root.rglob('*.kitty-backup-*')))
            for config_result, settings in (('touch config-ready', '{invalid json'), ('exit 7', '{}')):
                (root / 'claude/settings.json').write_text(settings)
                config_setup.write_text('#!/bin/bash\n' + config_result + '\n')
                result = subprocess.run(command, cwd=root, env=env, capture_output=True, text=True, timeout=10)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn('Terminal Setup Completed!', result.stdout)
                self.assertEqual((root / 'claude/settings.json').read_text(), settings)

    def test_empty_agent_directories_use_home_defaults(self):
        from kitty.constants import kitty_exe
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with patch.object(setup.Path, 'home', return_value=root), \
                 patch.object(setup.os, 'environ', {'CODEX_HOME': '', 'CLAUDE_CONFIG_DIR': ''}), \
                 patch.object(setup.shutil, 'which', return_value=kitty_exe()), \
                 patch.object(sys, 'argv', ['setup-hooks.py', '--apply']):
                setup.main()
            self.assertTrue((root / '.codex/hooks.json').is_file())
            self.assertTrue((root / '.claude/settings.json').is_file())

    @patch('agent_status.time.monotonic', return_value=0.0)
    def test_picker_collects_every_window_across_tabs_and_os_windows(self, clock):
        from agent_picker import rows_for_windows
        def pane(window_id, name):
            state = status.transition(None, event(name, window_id))
            return {'id': window_id, 'title': '工作\x1b[31m', 'user_vars': {status.STATE_VAR: json.dumps(state)}, 'foreground_processes': []}
        windows = [
            {'id': 1, 'tabs': [{'id': 1, 'title': 'A', 'windows': [pane(1, 'Stop'), pane(2, 'PermissionRequest')]},
                              {'id': 2, 'title': 'B', 'windows': [pane(3, 'UserPromptSubmit')]}]},
            {'id': 2, 'tabs': [{'id': 3, 'title': 'C', 'windows': [pane(4, 'SessionStart')]}]},
        ]
        picker = pane(5, 'SessionStart')
        picker['user_vars'][status.PICKER_VAR] = '1'
        windows[0]['tabs'][0]['windows'].append(picker)
        windows[0]['tabs'][0]['windows'].insert(1, {
            'id': 6, 'title': 'shell', 'user_vars': {}, 'foreground_processes': [],
        })
        windows[0]['tabs'][0]['windows'].append(pane(7, 'SessionEnd'))
        rows = rows_for_windows(windows, os.getpid())
        self.assertEqual([r['window_id'] for r in rows], [1, 2, 3, 4])
        self.assertEqual([r['status'] for r in rows], ['done', 'waiting', 'working', 'idle'])
        self.assertTrue(all('\x1b' not in r['label'] for r in rows))
        self.assertTrue(rows[0]['label'].startswith('✓ Codex: Turn completed  '))
        self.assertTrue(rows[1]['label'].startswith('! Codex: Action Required  '))

    def test_single_line_fallback_keeps_original_title_template(self):
        from kitty.config import load_config
        from kitty.fast_data_types import DECAWM, Screen
        from kitty.tab_bar import DrawData, ExtraData, TabBarData
        import renderer as tab_bar
        options = load_config(str(ROOT / '.config/kitty/kitty.conf'))
        data = DrawData(0, '', 0, '', (), options.active_tab_foreground, options.active_tab_background,
                        options.inactive_tab_foreground, options.inactive_tab_background, options.background,
                        options.tab_title_template, options.active_tab_title_template, '', 'round', 'bottom', 0,
                        os_window_id=1,
                        **({'max_tab_title_lines': 1, 'wrap_width': 0} if 'wrap_width' in DrawData._fields else {}))
        boss = SimpleNamespace(mappings=SimpleNamespace(current_keyboard_mode_name=''))
        tab = TabBarData(title='專案', tab_id=1, is_active=True, layout_name='stack')
        for width in (60, 32, 12):
            screen = Screen(None, 1, width)
            expected = Screen(None, 1, width)
            screen.reset_mode(DECAWM)
            expected.reset_mode(DECAWM)
            with patch.object(tab_bar, 'get_boss', return_value=boss), \
                 patch('kitty.tab_bar.get_boss', return_value=boss), \
                 patch('kitty.tab_bar.load_custom_draw_tab_module', return_value={}):
                tab_bar.draw_tab(data, screen, tab, 0, width - 4, 1, True, ExtraData())
                tab_bar.draw_tab_with_powerline(data, expected, tab, 0, width - 4, 1, True, ExtraData())
            self.assertEqual(str(screen.line(0)), str(expected.line(0)))
            self.assertEqual(screen.cursor.y, 0)
            self.assertLessEqual(screen.cursor.x, width)
            if width == 60:
                self.assertIn('專案 [ZOOM]', str(screen.line(0)))

    def test_native_picker_returns_selection_and_ignores_closed_windows(self):
        from kittens.runner import create_kitten_handler
        script = PLUGIN / 'agent_picker.py'
        handler = create_kitten_handler(str(script), [])
        self.assertFalse(handler.no_ui)
        self.assertTrue(handler.allow_remote_control)
        boss = SimpleNamespace(window_id_map={42: object()}, set_active_window=Mock())
        handler.handle_result(42, 100, boss)
        boss.set_active_window.assert_called_once_with(42, switch_os_window_if_needed=True)
        boss.set_active_window.reset_mock()
        handler.handle_result(999, 100, boss)
        boss.set_active_window.assert_not_called()

    def test_dynamic_tab_height_grows_shrinks_and_preserves_terminal_space(self):
        from kitty.config import load_config
        from kitty.fast_data_types import LEFT_EDGE, Region
        import renderer as tab_bar
        options = load_config(str(ROOT / '.config/kitty/kitty.conf'))
        mousemap = options.mousemap.copy()
        self.assertTrue(mousemap)
        panes = {1: [], 2: [], 3: []}
        first = SimpleNamespace(tab_bar=SimpleNamespace(draw_func=tab_bar.draw_tab), resize=Mock(),
                                tabs_to_be_shown_in_tab_bar=[SimpleNamespace(id=1), SimpleNamespace(id=2)])
        second = SimpleNamespace(tab_bar=SimpleNamespace(draw_func=tab_bar.draw_tab), resize=Mock(),
                                 tabs_to_be_shown_in_tab_bar=[SimpleNamespace(id=3)])
        boss = SimpleNamespace(tab_for_id=panes.get, os_window_map={1: first},
                               args=SimpleNamespace(debug_rendering=False, debug_font_fallback=False))
        dimensions = {1: (600, 20, 1), 2: (300, 40, 2)}

        def viewport(os_window_id):
            height, cell_height, scale = dimensions[os_window_id]
            region = Region((0, 0, 800, cell_height, 800, cell_height))
            return region, region, 800, height, 10, cell_height

        def set_options(updated, *args):
            nonlocal options
            self.assertEqual(updated.mousemap, mousemap)
            options = updated

        with patch.multiple(tab_bar, get_boss=Mock(return_value=boss), get_options=lambda: options,
                            viewport_for_window=viewport, set_options=set_options,
                            pt_to_px=lambda points, os_window_id: round(points * dimensions[os_window_id][2]),
                            is_wayland=Mock(return_value=False)):
            tab_bar.sync_tab_height()
            self.assertEqual(options.tab_bar_margin_height.inner, 0)
            first.resize.assert_not_called()

            panes[1] = [make_window(1, agent='codex', text='› '), make_window(2)]
            panes[1].append(SimpleNamespace(user_vars={status.PICKER_VAR: '1'}))
            tab_bar.sync_tab_height()
            self.assertEqual(options.tab_bar_margin_height.inner, 20)
            first.resize.assert_called_once_with()

            panes[2] = [make_window(i, agent='claude', text='❯ ') for i in range(3, 6)]
            tab_bar.sync_tab_height()
            self.assertEqual(options.tab_bar_margin_height.inner, 60)
            first.resize.reset_mock()
            # Focus and status changes do not change how many rows are needed.
            first.active_window = panes[2][0]
            panes[2][0].screen.draw('✻ Thinking… (esc to interrupt)\r\n❯ ')
            tab_bar.sync_tab_height()
            first.resize.assert_not_called()

            panes[2].clear()
            tab_bar.sync_tab_height()
            self.assertEqual(options.tab_bar_margin_height.inner, 20)
            panes[1][0].child.foreground_processes.clear()
            tab_bar.sync_tab_height()
            self.assertEqual(options.tab_bar_margin_height.inner, 0)

            panes[1] = [make_window(i, agent='codex', text='› ') for i in range(10, 30)]
            tab_bar.sync_tab_height()
            self.assertEqual(options.tab_bar_margin_height.inner, 180)
            self.assertLessEqual(options.tab_bar_margin_height.inner + 20, 600 / 3)
            dimensions[1] = (300, 20, 1)
            tab_bar.sync_tab_height()
            self.assertEqual(options.tab_bar_margin_height.inner, 80)
            dimensions[1] = (300, 30, 1.5)
            panes[1] = panes[1][:1]
            tab_bar.sync_tab_height()
            self.assertEqual(options.tab_bar_margin_height.inner, 20)
            dimensions[1] = (60, 30, 1.5)
            tab_bar.sync_tab_height()
            self.assertEqual(options.tab_bar_margin_height.inner, 0)

            # Global margins must also leave room in a smaller OS window.
            dimensions[1] = (600, 20, 1)
            panes[1] = [make_window(i, agent='codex', text='› ') for i in range(10, 14)]
            panes[3] = [make_window(30, agent='claude', text='❯ ')]
            boss.os_window_map[2] = second
            tab_bar.sync_tab_height()
            self.assertEqual(options.tab_bar_margin_height.inner, 20)
            second.resize.assert_called_once_with()
            del boss.os_window_map[2]
            tab_bar.sync_tab_height()
            self.assertEqual(options.tab_bar_margin_height.inner, 80)

            first.resize.reset_mock()
            options = options._replace(tab_bar_edge=LEFT_EDGE)
            tab_bar.sync_tab_height()
            first.resize.assert_not_called()

    @patch('agent_status.time.monotonic', return_value=0.0)
    def test_multiline_layout_status_updates_and_pane_clicks(self, clock):
        import importlib
        from kitty.config import load_config
        from kitty.fast_data_types import GLFW_MOUSE_BUTTON_LEFT, GLFW_PRESS, GLFW_RELEASE, Region
        from kitty import tab_bar as native
        import renderer as tab_bar
        original_layout = native.TabBar._agent_native_layout
        importlib.reload(tab_bar)
        importlib.reload(tab_bar)
        self.assertIs(native.TabBar._agent_native_layout, original_layout)
        self.addCleanup(native.clear_caches)

        class Windows(list):
            last_focused_window_with_progress_id = 0

        panes = {1: Windows(), 2: Windows()}
        for window_id in range(1, 17):
            state = status.transition(None, event('PermissionRequest' if window_id == 16 else 'UserPromptSubmit', window_id))
            if window_id == 2:
                state.update(agent='claude', status='done')
            panes[1 if window_id < 16 else 2].append(make_window(window_id, state))
        panes[1].insert(1, make_window(20))
        exited = status.transition(None, event('SessionEnd', 21))
        panes[1].append(make_window(21, exited))
        panes[1][3].user_vars.clear()
        panes[1][3].child.foreground_processes = [{'cmdline': ['/bin/codex']}]
        manager = SimpleNamespace(active_window=panes[1][0])
        boss = SimpleNamespace(tab_for_id=panes.get, set_active_window=Mock(), os_window_map={1: manager},
                               mappings=SimpleNamespace(current_keyboard_mode_name=''))
        tabs = [native.TabBarData(title='專案 A', tab_id=1, is_active=True, layout_name='stack'),
                native.TabBarData(title='project-b', tab_id=2)]
        cases = ((80, 20, 96, 'bottom', 5), (80, 20, 48, 'bottom', 3), (32, 20, 48, 'bottom', 3),
                 (12, 20, 48, 'bottom', 3), (80, 32, 48, 'bottom', 2),
                 (80, 60, 48, 'bottom', 1), (80, 20, 0, 'bottom', 1),
                 (80, 20, 48, 'top', 3))
        for columns, cell_height, margin, edge, rows in cases:
            with self.subTest(columns=columns, cell_height=cell_height, margin=margin, edge=edge):
                boss.os_window_map[1].active_window = panes[1][0]
                width, height = columns * 10, 400
                central_top, central_bottom = (0, height - cell_height - margin) if edge == 'bottom' else (cell_height + margin, height)
                bar_top = height - cell_height if edge == 'bottom' else 0
                central = Region((0, central_top, width, central_bottom, width, central_bottom - central_top))
                region = Region((0, bar_top, width, bar_top + cell_height, width, cell_height))
                viewport = (central, region, width, height, 10, cell_height)
                options = load_config(str(ROOT / '.config/kitty/kitty.conf'), overrides=(
                    f'tab_bar_edge {edge}', f'tab_bar_margin_height 0 {margin}', 'tab_bar_align center',
                ))
                native.clear_caches()
                with patch.multiple(native, get_options=Mock(return_value=options),
                                    cell_size_for_window=Mock(return_value=(10, cell_height)),
                                    pt_to_px=lambda value, window_id: int(value),
                                    viewport_for_window=Mock(return_value=viewport),
                                    get_boss=Mock(return_value=boss), set_tab_bar_render_data=Mock(),
                                    update_tab_bar_edge_colors=Mock(return_value=(False, True)),
                                    load_custom_draw_tab_module=Mock(return_value={'draw_tab': tab_bar.draw_tab})), \
                     patch.multiple(tab_bar, get_boss=Mock(return_value=boss),
                                    viewport_for_window=Mock(return_value=viewport), set_tab_bar_render_data=Mock()):
                    bar = native.TabBar(1)
                    bar.layout()
                    bar.update(tabs)
                    self.assertEqual(bar.screen.lines, rows)
                    g = bar.window_geometry
                    self.assertTrue(g.top >= central.bottom if edge == 'bottom' else g.bottom <= central.top)
                    for rect in bar.blank_rects:
                        self.assertTrue(rect.right <= g.left or rect.left >= g.right or rect.bottom <= g.top or rect.top >= g.bottom)
                    self.assertEqual(bar.screen.cursor.y, 0)
                    if rows == 1:
                        self.assertFalse(bar._agent_pane_hits)
                        continue
                    self.assertTrue(bar._agent_pane_hits)
                    row_targets = set()
                    for hit in bar._agent_pane_hits:
                        self.assertLess(hit['row'], rows)
                        self.assertLessEqual(hit['end'], columns)
                        text = str(bar.screen.line(hit['row']))[hit['start']:hit['end']]
                        color = {1: 0xFFFF55, 2: 0x69F197, 3: 0x888888, 16: 0xBD93F9}.get(hit['window_id'])
                        for column in range(hit['start'], hit['end']):
                            cursor = bar.screen.line(hit['row']).cursor_from(column)
                            self.assertEqual(cursor.bold, hit['window_id'] == 1)
                            if color is not None:
                                self.assertEqual(cursor.fg, native.as_rgb(color))
                        label = '· Codex: Working'
                        if hit['window_id'] == 2:
                            label = '✓ Claude: Turn completed'
                        if hit['window_id'] == 3:
                            label = '? Codex: Awaiting status'
                        if hit['window_id'] == 16:
                            label = '! Codex: Action Required'
                        if hit['window_id'] == 1:
                            label = '➤ ' + label
                        self.assertTrue(label.startswith(text.removesuffix('…')), text)
                        x, y = g.left + hit['start'] * 10 + 1, g.top + hit['row'] * cell_height + 1
                        tab_id = bar.tab_id_at(x, y)
                        self.assertEqual(tab_id, 2 if hit['window_id'] == 16 else 1)
                        self.assertNotIn((tab_id, hit['row']), row_targets)
                        row_targets.add((tab_id, hit['row']))
                    if columns >= 80:
                        self.assertIn('專案 A', str(bar.screen.line(0)))
                        self.assertIn('[ZOOM]', str(bar.screen.line(0)))
                        self.assertIn('! Codex: Action Required', str(bar.screen.line(1)))
                        self.assertIn(f'{17 - rows} more agents', str(bar.screen.line(rows - 1)))
                        if rows >= 4:
                            self.assertIn('➤ · Codex: Working', str(bar.screen.line(1)))
                            self.assertIn('✓ Claude: Turn completed', str(bar.screen.line(2)))
                            self.assertIn('? Codex: Awaiting status', str(bar.screen.line(3)))
                        hit = next(h for h in bar._agent_pane_hits if h['window_id'] == 16)
                    else:
                        self.assertTrue(any('…' in str(bar.screen.line(row)) for row in range(1, rows)))
                        hit = bar._agent_pane_hits[0]
                    manager = SimpleNamespace(tab_bar=bar, recent_tab_bar_mouse_events=Mock(), _agent_native_mouse=Mock())
                    x, y = g.left + hit['start'] * 10 + 1, g.top + hit['row'] * cell_height + 1
                    tab_bar.handle_pane_click(manager, x, y, GLFW_MOUSE_BUTTON_LEFT, 0, GLFW_PRESS)
                    boss.set_active_window.assert_called_with(hit['window_id'], switch_os_window_if_needed=True)
                    tab_bar.handle_pane_click(manager, x, y, GLFW_MOUSE_BUTTON_LEFT, 0, GLFW_RELEASE)
                    manager._agent_native_mouse.assert_not_called()
                    tab_bar.handle_pane_click(manager, x, g.top + 1, GLFW_MOUSE_BUTTON_LEFT, 0, GLFW_PRESS)
                    manager._agent_native_mouse.assert_called_once()
                    # A release outside the bar must not swallow the next tab click.
                    tab_bar.handle_pane_click(manager, x, y, GLFW_MOUSE_BUTTON_LEFT, 0, GLFW_PRESS)
                    tab_bar.handle_pane_click(manager, x, g.top + 1, GLFW_MOUSE_BUTTON_LEFT, 0, GLFW_PRESS)
                    tab_bar.handle_pane_click(manager, x, g.top + 1, GLFW_MOUSE_BUTTON_LEFT, 0, GLFW_RELEASE)
                    manager._agent_native_mouse.assert_called_with(x, g.top + 1, GLFW_MOUSE_BUTTON_LEFT, 0, GLFW_RELEASE)

                    # Removing a tab must clear both its text and its clickable rows.
                    bar.update(tabs[:1])
                    self.assertNotIn(16, [h['window_id'] for h in bar._agent_pane_hits])
                    self.assertNotIn('Action Required', ''.join(str(bar.screen.line(row)) for row in range(1, rows)))
                    if rows == 5:
                        all_panes = panes[1]
                        panes[1] = panes[1][:5]
                        bar.update(tabs[:1])
                        self.assertEqual([h['window_id'] for h in bar._agent_pane_hits], [1, 2, 3, 4])
                        self.assertEqual([h['row'] for h in bar._agent_pane_hits], [1, 2, 3, 4])
                        self.assertNotIn('more agents', str(bar.screen.line(4)))
                        extents = bar.tab_extents
                        boss.os_window_map[1].active_window = panes[1][2]
                        bar.update(tabs[:1])
                        self.assertEqual(bar.tab_extents, extents)
                        self.assertNotIn('➤', str(bar.screen.line(1)))
                        self.assertIn('➤ ✓ Claude: Turn completed', str(bar.screen.line(2)))
                        first, second = bar._agent_pane_hits[:2]
                        first_name = bar.screen.line(1).cursor_from(first['start'])
                        second_name = bar.screen.line(2).cursor_from(second['start'])
                        self.assertFalse(first_name.bold)
                        self.assertEqual(first_name.fg, native.as_rgb(0x77DBF4))
                        self.assertTrue(second_name.bold)
                        self.assertEqual(second_name.fg, native.as_rgb(0xFFFF55))
                        status_cell = bar.screen.line(2).cursor_from(second['start'] + len('➤ ✓ Claude: '))
                        self.assertEqual(status_cell.fg, native.as_rgb(0xFFFF55))
                        self.assertTrue(status_cell.bold)
                        boss.os_window_map[1].active_window = panes[1][1]
                        bar.update(tabs[:1])
                        for hit in bar._agent_pane_hits:
                            self.assertFalse(bar.screen.line(hit['row']).cursor_from(hit['start']).bold)
                            self.assertNotIn('➤', str(bar.screen.line(hit['row'])))
                        status_cell = bar.screen.line(2).cursor_from(second['start'] + len('✓ Claude: '))
                        self.assertEqual(status_cell.fg, native.as_rgb(0x69F197))
                        self.assertFalse(status_cell.bold)
                        panes[1] = all_panes
                    bar.update([])
                    self.assertFalse(bar._agent_pane_hits)
                    self.assertTrue(all(not str(bar.screen.line(row)).strip() for row in range(rows)))

    def test_disabled_plugin_hooks_do_not_read_or_send_events(self):
        from io import StringIO
        with patch.dict(os.environ, {}, clear=True), \
             patch('sys.stdin') as stdin, patch('sys.stdout', new_callable=StringIO) as output, \
             patch('builtins.open') as tty, patch('subprocess.run') as remote:
            status.hook_main('claude')
        stdin.read.assert_not_called()
        tty.assert_not_called()
        remote.assert_not_called()
        self.assertEqual(json.loads(output.getvalue()), {})

    def test_hook_without_controlling_tty_delivers_event_over_socket(self):
        from io import StringIO
        from kitty.constants import kitty_exe
        payload = status.HookInput(hook_event_name='StopFailure', session_id='main')
        window = make_window(42, agent='claude', text='❯ ')
        def deliver(command, **kwargs):
            self.assertEqual(command[:8], [kitty_exe(), '@', '--to', 'unix:/tmp/kitty-test',
                                           'set-user-vars', '--match', 'id:42', '--'])
            key, value = command[8].split('=', 1)
            status.on_set_user_var(None, window, {'key': key, 'value': value})
            return subprocess.CompletedProcess(command, 0, '', '')

        with patch.dict(os.environ, {'KITTY_AGENT_STATUS': '1', 'KITTY_PID': str(os.getpid()), 'KITTY_WINDOW_ID': '42',
                                     'KITTY_LISTEN_ON': 'unix:/tmp/kitty-test'}), \
             patch('sys.stdin', StringIO(json.dumps(payload))), patch('sys.stdout', new_callable=StringIO) as output, \
             patch('builtins.open', side_effect=OSError('no controlling terminal')), \
             patch('subprocess.run', side_effect=deliver) as run:
            status.hook_main('claude')
        run.assert_called_once()
        self.assertEqual(json.loads(output.getvalue()), {})
        self.assertEqual(status.window_status(window), ('claude', 'error'))

    def test_real_hook_writes_osc_to_controlling_tty_and_json_to_stdout(self):
        import base64
        from kitty.constants import kitty_exe
        script = str(PLUGIN / 'agent_status.py')
        code = f'import runpy; runpy.run_path({script!r}, run_name="__main__")'
        child, fd = pty.fork()
        if child == 0:
            os.environ['KITTY_AGENT_STATUS'] = '1'
            os.environ['KITTY_PID'] = '123'
            os.environ['KITTY_WINDOW_ID'] = '456'
            os.execv(kitty_exe(), [kitty_exe(), '+runpy', code, 'codex'])
        output = b''
        try:
            os.write(fd, b'{"hook_event_name":"Stop","session_id":"pty-session"}\n\x04')
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline and select.select([fd], [], [], 1)[0]:
                try:
                    chunk = os.read(fd, 8192)
                except OSError:
                    break
                if not chunk:
                    break
                output += chunk
            match = re.search(rb'\x1b\]1337;SetUserVar=dotfiles_agent_event=([^\x07]+)\x07', output)
            self.assertIsNotNone(match, output)
            payload = json.loads(base64.b64decode(match[1]))
            self.assertEqual((payload['event'], payload['kitty_pid'], payload['window_id']), ('Stop', 123, 456))
            self.assertIn(b'{}\r\n', output)
        finally:
            os.close(fd)
            if os.waitpid(child, os.WNOHANG)[0] == 0:
                os.kill(child, 15)
                os.waitpid(child, 0)


if __name__ == '__main__':
    try:
        import kitty.fast_data_types
    except ImportError:
        kitty = shutil.which('kitty')
        if not kitty:
            raise SystemExit('kitty must be installed to run the integration tests')
        code = f'import runpy; runpy.run_path({str(Path(__file__).resolve())!r}, run_name="__main__")'
        raise SystemExit(subprocess.call([kitty, '+runpy', code]))
    unittest.main(argv=[sys.argv[0]])
