"""Run: kitty +runpy 'import runpy; runpy.run_path(".config/kitty/test_relative_links.py")'"""

from pathlib import Path
from runpy import run_path
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
window = SimpleNamespace(cwd_of_child="/work/project")
other = SimpleNamespace(cwd_of_child="/work/other project")
boss = SimpleNamespace(
    window_id_map={1: window, 2: other}, active_window=window, open_url=Mock(), show_error=Mock()
)


def follow_link(url, target_window_id=1):
    with patch("kitty.open_actions.get_options", return_value=options):
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
    window.cwd_of_child = cwd
    boss.show_error.reset_mock()
    follow_link(report)
    boss.open_url.assert_not_called()
    boss.show_error.assert_called_once()
window.cwd_of_child = "/work/project"
print("PASS：缺少 window 安全返回，缺少可靠 cwd 則提示錯誤、不猜目錄")

markdown_url = f"file:///work/other%20project/{report}"
for macos, program in ((True, "default"), (False, "brave")):
    with patch("kitty.constants.is_macos", macos):
        open_markdown = run_path(str(config_dir / "open_markdown.py"))["handle_result"]
    boss.open_url.reset_mock()
    open_markdown(["open_markdown.py", markdown_url], None, 2, boss)
    boss.open_url.assert_called_once_with(markdown_url, program=program, cwd="/work/other project")
    boss.open_url.reset_mock()
    open_markdown(["open_markdown.py", markdown_url], None, -1, boss)
    boss.open_url.assert_not_called()
print("PASS：Markdown 在 macOS 使用系統預設程式，Linux 保留 Brave，並使用 target pane 的 cwd")


def dispatch_action(action):
    if action.func == "launch":
        boss.launch(*action.args)
        return True
    handler = run_path(str(config_dir / action.args[0]))["handle_result"]
    handler(action.args, None, 1, boss)
    return True


boss.open_url = MethodType(Boss.open_url, boss)
boss.dispatch_action = Mock(side_effect=dispatch_action)
boss.drain_actions = Mock()
boss.choose = Mock()
boss.launch = Mock()
boss.listening_on = ""
window.open_url_handler = None
window.hyperlink_open_confirmed = MethodType(Window.hyperlink_open_confirmed, window)

for policy in ("no", "ask", "yes"):
    security_options = load_config(str(config_dir / "kitty.conf"), overrides=[f"allow_hyperlinks {policy}"])
    for url, expected_launch in (
        (report, None),
        ("images/example%20image.png", ("--type=background", "xdg-open", "/work/project/images/example image.png")),
        ("docs/report.txt", None),
    ):
        boss.dispatch_action.reset_mock()
        boss.choose.reset_mock()
        boss.launch.reset_mock()
        with (
            patch("kitty.window.get_options", return_value=security_options),
            patch("kitty.window.get_boss", return_value=boss),
            patch("kitty.boss.get_options", return_value=security_options),
            patch("kitty.open_actions.get_options", return_value=security_options),
            patch("kitty.open_actions.config_dir", str(config_dir.resolve())),
            patch("kitty.window.set_clipboard_string") as clipboard,
            patch("subprocess.Popen") as launch,
        ):
            Window.open_url(window, url, hyperlink_id=82)
            if policy == "no":
                boss.dispatch_action.assert_not_called()
                boss.launch.assert_not_called()
                launch.assert_not_called()
                continue
            if policy == "ask":
                boss.choose.assert_called_once()
                boss.dispatch_action.assert_not_called()
                boss.launch.assert_not_called()
                launch.assert_not_called()
                confirmed = boss.choose.call_args.args[1]
                confirmed("n")
                confirmed("c")
                clipboard.assert_called_once_with(url)
                boss.dispatch_action.assert_not_called()
                boss.launch.assert_not_called()
                launch.assert_not_called()
                confirmed("o")
            if expected_launch is not None:
                boss.launch.assert_called_once_with(*expected_launch)
                launch.assert_not_called()
                continue
            boss.launch.assert_not_called()
            launch.assert_called_once()
            if launch.call_args.args[0][-1] != f"file:///work/project/{url}":
                raise RuntimeError(f"原生開檔流程仍使用錯誤路徑：{launch.call_args}")
            if launch.call_args.kwargs["cwd"] != "/work/project":
                raise RuntimeError("原生開檔流程未保留來源 pane 的工作目錄")
print("PASS：原生 OSC 8 流程保留 no／ask／yes、Markdown／圖片規則與預設 opener")
