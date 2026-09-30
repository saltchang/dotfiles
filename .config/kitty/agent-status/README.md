# Kitty agent 狀態列

在水平 tabs 顯示 Codex／Claude agent 狀態。

## 安裝

在 dotfiles 根目錄執行：

```sh
./setup-terminal.sh --kitty
```

會一併設定 kitty、agent 狀態列與 Codex／Claude hooks。已有的 agent 設定會先備份，保留其他 hooks。
完成後重啟 kitty 與 agents；Codex 在 `/hooks` 信任新增的 hooks。

## 開關

在 `kitty.conf` 保留此行即啟用，註解即停用：

```conf
include agent-status/agent-status.conf
```

切換後完整重啟 kitty。

## 操作

| 操作 | 功能 |
| --- | --- |
| 點 tab 名稱 | 切換 tab |
| 點 agent 狀態 | 跳到該 window |
| `Alt+a` | 開啟完整 agent 清單 |
| 清單中 `↑↓`／`j k` | 選擇 agent |
| 清單中 PageUp／PageDown | 翻頁 |
| 清單中 Enter | 跳轉 |
| 清單中 `q`／Esc | 關閉 |
| 清單中 `a` | 切換只看待回應、已完成、失敗的 agent |

高度自動調整，最多約視窗三分之一；出現 `N more agents` 時按 `Alt+a` 查看。

## 狀態

| 狀態 | 顏色 | 意義 |
| --- | --- | --- |
| ✻ Working | 青藍→紫→粉紅色波 | 思考或執行任務 |
| ▣ Background running | 青藍 | 本輪回覆結束，背景 shell／terminal 仍在跑 |
| ◐ Reconnecting | 橘色 | Codex 正在重試連線 |
| ! Action Required | 紫色 | 需要回答或批准 |
| ✓ Turn completed | 綠色 | 本輪回覆結束，不代表任務成功 |
| ○ Waiting for task | 淡藍 | 剛開啟、恢復 session，或自行中斷後等待指令 |
| × Failed | 紅色 | Agent 因錯誤停止 |
| ? Awaiting status | 灰色 | 已偵測到 agent，但無法判斷狀態 |

## 移除

若曾安裝 hooks，先執行：

```sh
uv run --no-project ~/.config/kitty/agent-status/setup-hooks.py --remove --apply
```

刪除 include、`tab_bar.py` 與 `agent-status/`，再重啟 kitty。

## 限制與排錯

- 限同一個 kitty process，也包含其他 OS windows。SSH／tmux 內的 agents 不支援。
- 背景狀態只涵蓋 shell／terminal，不包含 subagent 或排程。
- 偵測依賴畫面文字；視窗太窄或 agent 改版可能造成誤判，當 coding agent 版本有升級時請注意。
- 多行使用 kitty 內部 API，已在 kitty v0.48.2 驗證；排版異常時停用擴充並重啟 kitty。
