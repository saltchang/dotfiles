"""Run: kitty +runpy 'import runpy; runpy.run_path(".config/kitty/test_relative_links.py")'"""

from pathlib import Path
from runpy import run_path
from shutil import which
from types import MethodType, SimpleNamespace
from unittest.mock import Mock, patch

from kitty.boss import Boss
from kitty.config import load_config
from kitty.open_actions import actions_for_url
from kitty.window import Window


config_dir = Path(__file__).parent
options = load_config(str(config_dir / "kitty.conf"))
rules_file = config_dir / "open-actions.conf"
rules = rules_file.read_text() if rules_file.exists() else ""
report = "openspec/changes/example-feature/implementation-report.md"
window = SimpleNamespace(cwd_of_child="/work/project", child=SimpleNamespace(child_fd=10))
other = SimpleNamespace(cwd_of_child="/work/other project", child=SimpleNamespace(child_fd=11))
foreground_pids = {10: 100, 11: 200}
process_cwds = {100: "/work/project", 200: "/work/other project"}
boss = SimpleNamespace(
    window_id_map={1: window, 2: other}, active_window=window, open_url=Mock(), show_error=Mock()
)


def follow_link(url, target_window_id=1):
    with (
        patch("kitty.open_actions.get_options", return_value=options),
        patch("os.tcgetpgrp", side_effect=foreground_pids.__getitem__),
        patch("kitty.child.cwd_of_process", side_effect=process_cwds.__getitem__),
    ):
        actions = list(actions_for_url(url, actions_spec=rules))
        if not actions:
            raise RuntimeError("FAIL：相對連結未被處理，會從 kitty 程序目錄找檔案")
        action = actions[0]
        if action.func != "kitten":
            raise RuntimeError("相對連結必須交給 kitten，不能直接送給系統 opener")
        handle_result = run_path(str(config_dir / action.args[0]))["handle_result"]
        handle_result(action.args, None, target_window_id, boss)


follow_link(report)
boss.open_url.assert_called_once_with(f"file:///work/project/{report}", cwd="/work/project")
boss.open_url.reset_mock()
follow_link(report, 2)
boss.open_url.assert_called_once_with(f"file:///work/other%20project/{report}", cwd="/work/other project")
print("PASS：原報告相對連結使用 target pane，而非其他 pane 或程序目錄")

window.cwd_of_child = "/work/mcp-parent"
boss.open_url.reset_mock()
follow_link(report)
boss.open_url.assert_called_once_with(f"file:///work/project/{report}", cwd="/work/project")
window.cwd_of_child = "/work/project"
print("PASS：MCP 子程序的目錄不會覆蓋前景主程序的工作目錄")

boss.open_url.reset_mock()
follow_link("docs/報告%20v1%23%2520.md?review=1#摘要")
boss.open_url.assert_called_once_with(
    "file:///work/project/docs/%E5%A0%B1%E5%91%8A%20v1%23%2520.md?review=1#摘要",
    cwd="/work/project",
)
print("PASS：中文、空白與百分比只解碼一次，query／fragment 保留")

handle_result = run_path(str(config_dir / "relative_links.py"))["handle_result"]
boss.open_url.reset_mock()
for url in (
    "http://example.com/report.md", "https://example.com/report.md", "file:///tmp/report.md",
    "ssh://host/report.md", "/tmp/report.md", "//host/report.md", "#section", "?review=1", "",
    "%2Ftmp/report.md", "%2F%2Fhost/report.md",
):
    with patch("kitty.open_actions.get_options", return_value=options):
        actions = list(actions_for_url(url, actions_spec=rules))
        if any(action.func == "kitten" and action.args[0] == "relative_links.py" for action in actions):
            raise RuntimeError(f"不應將非本機相對路徑交給 relative_links：{url!r}")
    handle_result(["relative_links.py", url], None, 1, boss)
    boss.open_url.assert_not_called()
print("PASS：其他 URL、絕對路徑與編碼後的絕對路徑不會被轉換")

follow_link(report, -1)
boss.open_url.assert_not_called()
boss.show_error.assert_not_called()
for cwd in (None, "", "relative/directory"):
    process_cwds[100] = cwd
    boss.show_error.reset_mock()
    follow_link(report)
    boss.open_url.assert_not_called()
    boss.show_error.assert_called_once()
process_cwds[100] = "/work/project"
print("PASS：缺少 window 安全返回，缺少可靠 cwd 則提示錯誤、不猜目錄")

with (
    patch("os.tcgetpgrp", return_value=100) as foreground_pid,
    patch("kitty.child.cwd_of_process", return_value="/work/project") as process_cwd,
):
    handle_result = run_path(str(config_dir / "relative_links.py"))["handle_result"]
    for lookup in (foreground_pid, process_cwd):
        lookup.side_effect = OSError("foreground process unavailable")
        boss.open_url.reset_mock()
        boss.show_error.reset_mock()
        handle_result(["relative_links.py", report], None, 1, boss)
        boss.open_url.assert_not_called()
        boss.show_error.assert_called_once()
        lookup.side_effect = None
print("PASS：前景程序無法查詢時提示錯誤，不回退到 MCP 或 shell 的目錄")

markdown_url = f"file:///work/other%20project/{report}"
for macos, program in ((True, "default"), (False, "brave")):
    with patch("kitty.constants.is_macos", macos):
        open_markdown = run_path(str(config_dir / "open_markdown.py"))["handle_result"]
    boss.open_url.reset_mock()
    open_markdown(["open_markdown.py", markdown_url], None, 2, boss)
    boss.open_url.assert_called_once_with(markdown_url, program=program)
    boss.open_url.reset_mock()
    open_markdown(["open_markdown.py", markdown_url], None, -1, boss)
    boss.open_url.assert_not_called()
print("PASS：Markdown 在 macOS 使用系統預設程式，Linux 保留 Brave，完整網址不再依賴 pane cwd")

image_url = "file:///work/other%20project/images/%E6%88%AA%E5%9C%96%20%231%2520.png"
for macos, program in ((True, "open"), (False, "xdg-open")):
    with (
        patch("kitty.open_actions.get_options", return_value=options),
        patch("kitty.utils.is_macos", macos),
        patch("subprocess.Popen") as launch,
    ):
        action, = actions_for_url(image_url, actions_spec=rules)
        if action.func != "kitten":
            raise RuntimeError("圖片必須交給跨平台系統 opener，不能寫死啟動指令")
        open_image = run_path(str(config_dir / action.args[0]))["handle_result"]
        open_image(action.args, None, 2, boss)
        launch.assert_called_once()
        if launch.call_args.args[0] != (program, "/work/other project/images/截圖 #1%20.png"):
            raise RuntimeError(f"圖片未使用正確的平台 opener 或解碼路徑：{launch.call_args}")
        launch.reset_mock()
        open_image(action.args, None, -1, boss)
        open_image([action.args[0]], None, 2, boss)
        launch.assert_not_called()
print("PASS：圖片在 macOS 使用 open、Linux 使用 xdg-open，保留中文與空白檔名")


def dispatch_action(action):
    handler = run_path(str(config_dir / action.args[0]))["handle_result"]
    handler(action.args, None, 1, boss)
    return True


boss.open_url = MethodType(Boss.open_url, boss)
boss.dispatch_action = Mock(side_effect=dispatch_action)
boss.drain_actions = Mock()
boss.choose = Mock()
boss.listening_on = ""
window.open_url_handler = None
window.hyperlink_open_confirmed = MethodType(Window.hyperlink_open_confirmed, window)
window.cwd_of_child = "/work/mcp-parent"

for policy in ("no", "ask", "yes"):
    security_options = load_config(str(config_dir / "kitty.conf"), overrides=[f"allow_hyperlinks {policy}"])
    for url, expected_argument, expected_cwd in (
        (report, f"file:///work/project/{report}", None),
        ("images/example%20image.png", "/work/project/images/example image.png", None),
        ("docs/report.txt", "file:///work/project/docs/report.txt", "/work/project"),
    ):
        boss.dispatch_action.reset_mock()
        boss.choose.reset_mock()
        with (
            patch("kitty.window.get_options", return_value=security_options),
            patch("kitty.window.get_boss", return_value=boss),
            patch("kitty.boss.get_options", return_value=security_options),
            patch("kitty.open_actions.get_options", return_value=security_options),
            patch("kitty.open_actions.config_dir", str(config_dir.resolve())),
            patch("os.tcgetpgrp", side_effect=foreground_pids.__getitem__),
            patch("kitty.child.cwd_of_process", side_effect=process_cwds.__getitem__),
            patch("kitty.window.set_clipboard_string") as clipboard,
            patch("subprocess.Popen") as launch,
        ):
            Window.open_url(window, url, hyperlink_id=82)
            if policy == "no":
                boss.dispatch_action.assert_not_called()
                launch.assert_not_called()
                continue
            if policy == "ask":
                boss.choose.assert_called_once()
                boss.dispatch_action.assert_not_called()
                launch.assert_not_called()
                confirmed = boss.choose.call_args.args[1]
                confirmed("n")
                confirmed("c")
                clipboard.assert_called_once_with(url)
                boss.dispatch_action.assert_not_called()
                launch.assert_not_called()
                confirmed("o")
            launch.assert_called_once()
            if url.startswith("images/") and which(launch.call_args.args[0][0]) is None:
                raise RuntimeError(f"圖片 opener 在目前系統不存在：{launch.call_args.args[0][0]}")
            if launch.call_args.args[0][-1] != expected_argument:
                raise RuntimeError(f"原生開檔流程仍使用錯誤路徑：{launch.call_args}")
            if launch.call_args.kwargs["cwd"] != expected_cwd:
                raise RuntimeError(f"原生開檔流程仍使用錯誤目錄：{launch.call_args}")
print("PASS：原生 OSC 8 流程保留 no／ask／yes、Markdown／圖片規則與預設 opener")
