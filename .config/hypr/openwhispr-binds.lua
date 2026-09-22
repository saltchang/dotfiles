-- OpenWhispr keybinds (managed automatically)
-- If you delete this file, also remove the matching load line from your Hyprland config.
hl.bind("ALT + SPACE", hl.dsp.exec_cmd("dbus-send --session --type=method_call --dest=com.openwhispr.App /com/openwhispr/App com.openwhispr.App.Toggle"))
