#!/usr/bin/env bash

# mudow GUI launcher: opens the quickshell configuration as a single
# dialog app. Submitting hides the window while the download runs, so a
# launch while one is in flight is refused by the instance guard — that
# refusal is surfaced as a notification instead of failing silently.

CONFIG_DIR="${MUDOW_GUI_CONFIG:-$HOME/.config/quickshell/rofi-music-dl}"

if ! command -v qs >/dev/null 2>&1 && ! command -v quickshell >/dev/null 2>&1; then
    echo "mudow-gui: quickshell (qs) is not installed" >&2
    exit 1
fi

if [[ ! -f "$CONFIG_DIR/shell.qml" ]]; then
    echo "mudow-gui: config not found at $CONFIG_DIR/shell.qml" >&2
    echo "mudow-gui: run the installer to install the quickshell config" >&2
    exit 1
fi

QS_BIN="$(command -v qs || command -v quickshell)"

# -n refuses to start a second instance of the same config. The GUI lives
# in the background while a download runs, so the refusal is expected
# behavior; it exits immediately, while a real session ends late (and may
# exit 143 on SIGTERM from its own shutdown) — hence the timing check.
STARTED_AT="$(date +%s%N)"
if ! "$QS_BIN" -n -p "$CONFIG_DIR"; then
    if (( $(date +%s%N) - STARTED_AT < 300000000 )); then
        notify-send -i "download" "YouTube Download" "mudow GUI is already running"
    fi
fi