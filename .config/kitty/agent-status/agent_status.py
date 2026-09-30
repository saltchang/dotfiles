"""Observe agent UI in every kitty pane; optional hooks supply precise events."""

from __future__ import annotations

import base64
import json
import os
import re
import subprocess
import sys
import time
import unicodedata
from collections.abc import Callable
from typing import NotRequired, TypedDict

EVENT_VAR = "dotfiles_agent_event"
STATE_VAR = "dotfiles_agent_state"
PICKER_VAR = "dotfiles_agent_picker"
FRAME_INTERVAL = 0.2
LABELS = {
    "working": ("·✢✳✶✻✽", "Working", 0x77DBF4),
    "background": ("□▣■", "Background running", 0x8BE9FD),
    "reconnecting": ("◐◓◑◒", "Reconnecting", 0xFFB86C),
    "waiting": ("!!  ", "Action Required", 0xBD93F9),
    "done": ("✓", "Turn completed", 0x69F197),
    "idle": ("○", "Waiting for task", 0xC6E8F1),
    "error": ("××  ", "Failed", 0xFF4444),
    "exited": ("-", "Exited", 0x888888),
    "unknown": ("?", "Awaiting status", 0x888888),
    "shell": ("·", "No agent", 0x888888),
}


def status_text(agent: str, status: str, active: bool = False) -> str:
    frames, label, _ = LABELS[status]
    icon = frames[int(time.monotonic() / FRAME_INTERVAL) % len(frames)]
    prefix = "➤ " if active else ""
    return f"{prefix}{icon} {agent.title()}: {label}"


class BackgroundTask(TypedDict, total=False):
    type: str
    status: str


class HookInput(TypedDict, total=False):
    hook_event_name: str
    session_id: str
    transcript_path: str
    agent_id: str
    tool_name: str
    notification_type: str
    source: str
    background_tasks: list[BackgroundTask]


class AgentEvent(TypedDict):
    agent: str
    event: str
    session: str
    transcript: str
    tool: str
    notification: str
    source: str
    background: bool
    kitty_pid: int
    window_id: int


class AgentState(TypedDict):
    agent: str
    status: str
    session: str
    transcript: str
    waiting_tool: str
    kitty_pid: int
    window_id: int
    agent_pid: NotRequired[int]


class WatchEvent(TypedDict, total=False):
    key: str
    value: str | None
    is_start: bool


def clean_text(value: str) -> str:
    return "".join(c for c in value if not unicodedata.category(c).startswith("C"))


def read_state(raw: str, kitty_pid: int, window_id: int) -> AgentState | None:
    try:
        state = json.loads(raw)
    except (ValueError, TypeError):
        return None
    if not isinstance(state, dict):
        return None
    if state.get("kitty_pid") != kitty_pid or state.get("window_id") != window_id:
        return None
    if (
        state.get("agent") not in ("codex", "claude")
        or state.get("status") not in LABELS
    ):
        return None
    if not all(
        isinstance(state.get(k), str) for k in ("session", "transcript", "waiting_tool")
    ):
        return None
    return state


def transition(previous: AgentState | None, event: AgentEvent) -> AgentState | None:
    """PermissionRequest -> waiting; unrelated tool completions keep it waiting."""
    name = event["event"]
    if (
        previous
        and previous["session"]
        and name not in ("SessionStart", "UserPromptSubmit")
    ):
        if event["session"] != previous["session"]:
            return previous
        if previous["transcript"] and event["transcript"] != previous["transcript"]:
            return previous

    status = ""
    waiting_tool = ""
    if name == "SessionStart":
        if (
            previous
            and previous["session"] == event["session"]
            and event["source"] != "compact"
        ):
            return previous
        status = "working" if event["source"] == "compact" else "idle"
    elif name in ("UserPromptSubmit", "PreCompact", "PostCompact"):
        status = "working"
    elif name == "PermissionRequest":
        status, waiting_tool = "waiting", event["tool"]
    elif name == "PreToolUse":
        tool = event["tool"].split(".")[-1]
        if tool in (
            "AskUserQuestion",
            "request_user_input",
            "request_user_input_async",
        ):
            status, waiting_tool = "waiting", event["tool"]
        elif previous and previous["status"] == "waiting":
            return previous
        else:
            status = "working"
    elif name in ("PostToolUse", "PostToolUseFailure"):
        if previous and previous["status"] in (
            "done",
            "background",
            "idle",
            "exited",
            "error",
        ):
            return previous
        if (
            previous
            and previous["status"] == "waiting"
            and previous["waiting_tool"] != event["tool"]
        ):
            return previous
        if (
            name == "PostToolUse"
            and previous
            and previous["waiting_tool"].endswith("request_user_input_async")
        ):
            return previous
        status = "working"
    elif name == "Stop":
        if (
            previous
            and previous["status"] == "waiting"
            and previous["waiting_tool"].endswith("request_user_input_async")
        ):
            return previous
        status = "background" if event["background"] else "done"
    elif name == "StopFailure":
        status = "error"
    elif name == "Interrupt":
        status = "idle"
    elif name == "SessionEnd":
        status = "exited"
    elif name == "Notification":
        if event["notification"] in (
            "permission_prompt",
            "elicitation_dialog",
            "elicitation_url_dialog",
            "agent_needs_input",
        ):
            status = "waiting"
            waiting_tool = previous["waiting_tool"] if previous else ""
        elif event["notification"] == "idle_prompt":
            if previous and previous["status"] in (
                "working",
                "background",
                "reconnecting",
                "error",
            ):
                return previous
            status = "done"
    if not status:
        return previous
    return AgentState(
        agent=event["agent"],
        status=status,
        session=event["session"],
        transcript=event["transcript"],
        waiting_tool=waiting_tool,
        kitty_pid=event["kitty_pid"],
        window_id=event["window_id"],
    )


def normalize_hook(
    agent: str, payload: HookInput, kitty_pid: int, window_id: int
) -> AgentEvent | None:
    if (
        agent not in ("codex", "claude")
        or not isinstance(payload, dict)
        or payload.get("agent_id")
    ):
        return None
    if not payload.get("session_id") or kitty_pid <= 0 or window_id <= 0:
        return None
    keys = (
        "hook_event_name",
        "session_id",
        "transcript_path",
        "tool_name",
        "notification_type",
        "source",
    )
    if any(
        payload.get(k) is not None and not isinstance(payload[k], str) for k in keys
    ):
        return None
    tasks = payload.get("background_tasks") or []
    if not isinstance(tasks, list):
        return None
    return AgentEvent(
        agent=agent,
        event=payload.get("hook_event_name", ""),
        session=payload["session_id"],
        transcript=payload.get("transcript_path") or "",
        tool=payload.get("tool_name", ""),
        notification=payload.get("notification_type", ""),
        source=payload.get("source", ""),
        background=any(
            isinstance(task, dict)
            and task.get("type") == "shell"
            and task.get("status") == "running"
            for task in tasks
        ),
        kitty_pid=kitty_pid,
        window_id=window_id,
    )


def hook_main(agent: str) -> None:
    try:
        if os.environ.get("KITTY_AGENT_STATUS") != "1":
            return
        if not os.environ.get("KITTY_WINDOW_ID") or not os.environ.get("KITTY_PID"):
            return
        event = normalize_hook(
            agent,
            json.load(sys.stdin),
            int(os.environ["KITTY_PID"]),
            int(os.environ["KITTY_WINDOW_ID"]),
        )
        if event is None:
            return
        payload = json.dumps(event, ensure_ascii=True)
        encoded = base64.b64encode(payload.encode()).decode()
        # stdout belongs to the agent's hook protocol, not the terminal emulator.
        try:
            with open("/dev/tty", "wb", buffering=0) as tty:
                tty.write(f"\x1b]1337;SetUserVar={EVENT_VAR}={encoded}\x07".encode())
        except OSError:
            # Claude detaches hook processes from the controlling terminal.
            address = os.environ.get("KITTY_LISTEN_ON")
            if not address:
                raise
            from kitty.constants import kitty_exe

            fds = (int(address[3:]),) if address.startswith("fd:") else ()
            subprocess.run(
                [
                    kitty_exe(),
                    "@",
                    "--to",
                    address,
                    "set-user-vars",
                    "--match",
                    f"id:{event['window_id']}",
                    "--",
                    f"{EVENT_VAR}={payload}",
                ],
                capture_output=True,
                text=True,
                check=True,
                timeout=2,
                pass_fds=fds,
            )
    except (OSError, ValueError, TypeError, subprocess.SubprocessError) as exc:
        print(f"kitty agent hook: {exc}", file=sys.stderr)
    finally:
        print("{}")


def on_set_user_var(boss, window, data: WatchEvent) -> None:
    if data.get("key") != EVENT_VAR or not data.get("value"):
        return
    try:
        event = json.loads(data["value"])
        if event["kitty_pid"] != os.getpid() or event["window_id"] != window.id:
            return
        if event["agent"] not in ("codex", "claude"):
            return
        if not all(
            isinstance(event[k], str)
            for k in (
                "event",
                "session",
                "transcript",
                "tool",
                "notification",
                "source",
            )
        ):
            return
        state = transition(
            read_state(window.user_vars.get(STATE_VAR, ""), os.getpid(), window.id),
            event,
        )
    except (ValueError, TypeError, KeyError):
        return
    if state:
        window.set_user_var(STATE_VAR, json.dumps(state))
        tab = window.tabref()
        if tab:
            tab.mark_tab_bar_dirty()


def on_cmd_startstop(boss, window, data: WatchEvent) -> None:
    state = read_state(window.user_vars.get(STATE_VAR, ""), os.getpid(), window.id)
    if not state:
        return
    if data["is_start"]:
        window.set_user_var(STATE_VAR, None)
        window.set_user_var(EVENT_VAR, None)
    else:
        state["status"] = "exited"
        window.set_user_var(STATE_VAR, json.dumps(state))
    tab = window.tabref()
    if tab:
        tab.mark_tab_bar_dirty()


def describe(
    raw: str, kitty_pid: int, window_id: int, commands: list[list[str]]
) -> tuple[str, str]:
    state = read_state(raw, kitty_pid, window_id)
    if state:
        return state["agent"], state["status"]
    for command in commands:
        if not command:
            continue
        name = os.path.basename(command[0])
        if name in ("node", "nodejs", "bun") and len(command) > 1:
            name = os.path.basename(command[1])
        if name in ("codex", "claude", "codex.js", "claude.js"):
            return name.split(".")[0], "unknown"
    return "", "shell"


def screen_status(agent: str, text: str, previous: str = "unknown") -> str:
    """'• Working (12s • esc to interrupt)\n› ' -> working, without hooks."""
    # ponytail: UI wording is version-dependent; add patterns when agent UIs change.
    lines = text.rstrip().splitlines()[-30:]
    prompt = "›" if agent == "codex" else "❯"
    prompts = [i for i, line in enumerate(lines) if line.lstrip().startswith(prompt)]
    last_prompt = prompts[-1] if prompts else len(lines)
    choices = bool(prompts and re.match(r"^\s*[›❯>]\s*\d+[.)]\s", lines[last_prompt]))
    footer = "\n".join(
        line for line in lines[-5:] if not line.lstrip().startswith(prompt)
    ).lower()
    control_end = last_prompt
    if agent == "codex":
        # Queued questions/answers sit between the running hint and the input box.
        start = prompts[-2] + 1 if len(prompts) > 1 else 0
        for i in range(start, last_prompt):
            if lines[i].strip() == "• Queued follow-up inputs" or lines[i].startswith(
                "• Messages to be submitted after next tool call ("
            ):
                control_end = i
        queued = "\n".join(lines[control_end:last_prompt])
        if re.search(
            r"^\s*\? [1-9]\d* questions?\b[^\n]*\n\s*shift\+← to answer\s*$",
            queued,
            re.MULTILINE,
        ):
            return "waiting"
    if (
        agent == "codex"
        and "submit with " in footer
        and any(re.match(r"^\s*Question \d+/\d+", line) for line in lines)
    ):
        return "waiting"
    if choices and re.search(
        r"\b(?:enter|return)\b.*\b(?:select|confirm|submit|yes)\b|esc to cancel", footer
    ):
        return "waiting"
    if re.search(r"\b(?:enter|return) to (?:confirm|select)\b.*\besc\b", footer):
        return "waiting"

    latest = ""
    if agent == "codex":
        # Top-level history entries distinguish terminal errors from indented tool output.
        messages = [line for line in lines[:control_end] if re.match(r"^[•■›]\s", line)]
        latest = messages[-1] if messages else ""
        # Reconnecting also shows the generic interrupt hint; match it first.
        if re.match(r"^• Reconnecting(?:\.{3}|…)", latest):
            return "reconnecting"

    controls = "\n".join(lines[max(0, control_end - 5) : control_end]).lower()
    # Claude's spinner can omit the interrupt shortcut, including during thinking.
    if agent == "claude" and re.search(
        r"^\s*[·*✢✳✶✻✽]\s+[^\n…]+…(?:\s*\([^\n]*\))?\s*$", controls, re.MULTILINE
    ):
        return "working"
    # While running, both agents retain an input box; the interrupt hint wins.
    if re.search(
        r"^\s*[•·*✢✳✶✻✽✺✹✷✸✼✵].*\([^)]*\besc to (?:interrupt|stop)\b",
        controls,
        re.MULTILINE,
    ):
        return "working"
    if re.search(r"^\s*esc to (?:interrupt|stop)\b", footer, re.MULTILINE):
        return "working"
    if not prompts or choices:
        return ""
    if agent == "codex" and latest.startswith("■ "):
        return (
            "idle"
            if re.match(
                r"^■ (?:Conversation interrupted|Goal budget reached)\b", latest
            )
            else "error"
        )
    if agent == "claude" and re.search(r"⎿\s*Interrupted", controls, re.IGNORECASE):
        return "idle"
    if agent == "claude":
        messages = [
            line.strip()
            for line in lines[:last_prompt]
            if re.match(r"^\s*[⏺●]\s", line)
        ]
        if messages and re.match(
            r"^[⏺●]\s+(?:Please run /login\s*·\s*)?API Error:",
            messages[-1],
            re.IGNORECASE,
        ):
            return "error"
    if previous == "error":
        return previous
    # Only live controls count; old replies can still mention finished background jobs.
    if agent == "codex" and re.search(
        r"^\s*[1-9]\d* background terminals? running · /ps to view · /stop to close\s*$",
        controls,
        re.MULTILINE,
    ):
        return "background"
    if agent == "claude":
        input_footer = "\n".join(lines[last_prompt + 1 :]).lower()
        if re.search(
            r"(?:^|·)\s*[1-9]\d* shells?\s*(?:·|$)", input_footer, re.MULTILINE
        ):
            return "background"
    return (
        "done"
        if previous in ("done", "working", "background", "reconnecting", "waiting")
        else "idle"
    )


def window_status(window) -> tuple[str, str]:
    state = read_state(window.user_vars.get(STATE_VAR, ""), os.getpid(), window.id)
    agent, pid = "", 0
    for process in window.child.foreground_processes:
        agent, _ = describe("", os.getpid(), window.id, [process["cmdline"]])
        if agent:
            pid = process.get("pid", 0)
            break
    if not agent:
        if state:
            window.set_user_var(STATE_VAR, None)
        return "", "shell"
    if state and (state["agent"] != agent or state.get("agent_pid", pid) != pid):
        state = None
    previous = state["status"] if state else "unknown"
    text: list[str] = []
    # Join terminal-wrapped lines and read the live buffer even when scrolled up.
    window.screen.as_text_non_visual(text.append, False, False)
    observed = screen_status(agent, "".join(text), previous) or previous
    current = (
        state.copy()
        if state
        else AgentState(
            agent=agent,
            status=observed,
            session="",
            transcript="",
            waiting_tool="",
            kitty_pid=os.getpid(),
            window_id=window.id,
        )
    )
    current.update(status=observed, agent_pid=pid)
    if current != state:
        window.set_user_var(STATE_VAR, json.dumps(current))
    return agent, observed


def poll_windows(boss) -> None:
    for window in tuple(boss.window_id_map.values()):
        if window.user_vars.get(PICKER_VAR):
            continue
        before = window.user_vars.get(STATE_VAR)
        _, status = window_status(window)
        if before != window.user_vars.get(STATE_VAR) or len(LABELS[status][0]) > 1:
            tab = window.tabref()
            if tab:
                tab.mark_tab_bar_dirty()


def start_monitor(after_poll: Callable[[], None] | None = None) -> None:
    from kitty.fast_data_types import add_timer, get_boss, remove_timer

    boss = get_boss()
    if boss is None:
        return
    from kitty.launch import load_watch_modules

    watchers = load_watch_modules([__file__])
    if watchers:
        for window in boss.window_id_map.values():
            window.watchers.add(watchers)
    # Keep one timer per kitty process, including across custom-tab-bar reloads.
    previous = getattr(boss, "_agent_status_timer", None)
    if previous is not None:
        remove_timer(previous)

    def tick(timer_id):
        poll_windows(boss)
        if after_poll:
            after_poll()

    boss._agent_status_timer = add_timer(tick, FRAME_INTERVAL, True)


if __name__ == "__main__":
    hook_main(sys.argv[1] if len(sys.argv) > 1 else "")
