#!/usr/bin/env bash

escape_markup() {
    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g;'
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROFI_THEME="$SCRIPT_DIR/style.rasi"
YT_MUSIC_DL="/usr/bin/mudow"

# Checks if the music downloader script exists
if [[ ! -x "$YT_MUSIC_DL" ]]; then
    rofi -e "Error: mudow not found in /usr/bin/mudow" -theme "$ROFI_THEME"
    exit 1
fi

# URL
URL=$(rofi -dmenu \
    -p "YouTube URL: " \
    -mesg "Paste the YouTube video or playlist URL" \
    -theme "$ROFI_THEME")

[[ -z "$URL" ]] && exit 0

# Optional destination folder
DEST=$(rofi -dmenu \
    -p "Destination (optional)" \
    -mesg "Leave empty for default:  ~/Music/$(date +%F)-music" \
    -theme "$ROFI_THEME")

# URL Type
TYPE=$(echo -e " Single video\n󰉍 Playlist" | rofi -dmenu \
    -p "Download type" \
    -theme "$ROFI_THEME" \
    -selected-row 0 \
    -format i)

[[ -z "$TYPE" ]] && exit 0

# Builds command (array keeps arguments with spaces intact)
CMD=("$YT_MUSIC_DL")
[[ -n "$DEST" ]] && CMD+=(-p "$DEST")
[[ "$TYPE" == "1" ]] && CMD+=(-P)
CMD+=("$URL")

# Confirmation
MESG_CMD=$(printf '%q ' "${CMD[@]}")
MESG_CMD=$(echo "Command: $MESG_CMD" | escape_markup)
CONFIRM=$(echo -e "󰸞 Download\n Cancel" | rofi -dmenu \
    -p "Ready to download" \
    -mesg "$MESG_CMD" \
    -theme "$ROFI_THEME" \
    -selected-row 0 \
    -format i)

# Execution
[[ -z "$CONFIRM" ]] && exit 0

if [[ "$CONFIRM" == "0" ]]; then
    notify-send -i "download" "YouTube Download" "Starting download..."
    if "${CMD[@]}"; then
        notify-send -i "download" "YouTube Download" "Download finished!"
    else
        notify-send -i "dialog-error" "YouTube Download" "Failed!"
    fi
fi
