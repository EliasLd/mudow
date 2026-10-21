#!/usr/bin/env bash

# Configuration
DEFAULT_DIR="$HOME/Music/$(date +%F)-music"
ARCHIVE_FILE="archive.txt"

# Parse arguments
help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] URL

Options:
    -p, --path DIR      Download directory (default: Music/DATE-music)
    -P, --playlist      Download entire playlist
    -h, --help          Show this help 

Examples:
    $(basename "$0") https://youtube.com/watch?v=xxxxx
    $(basename "$0") -p ~/Music/new-music -P https://youtube.com/playlist?list=xxxxx

EOF
}

PLAYLIST=false
DOWNLOAD_DIR=""

# Check if no arguments provided
if [[ $# -eq 0 ]]; then
    help
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--path)
            if [[ $# -lt 2 || -z "$2" || "$2" == -* ]]; then
                echo "Error: --path requires a directory argument"
                echo ""
                help
                exit 1
            fi
            DOWNLOAD_DIR="$2"
            shift 2
            ;;
        -P|--playlist)
            PLAYLIST=true
            shift
            ;;
        -h|--help)
            help
            exit 0
            ;;
        -*)
            echo "Error: Unknown option: $1"
            echo ""
            help
            exit 1
            ;;
        *)
            if [[ -n "$URL" ]]; then
                echo "Error: Only one URL is supported"
                echo ""
                help
                exit 1
            fi
            URL="$1"
            shift
            ;;
    esac
done

# Validation
if [[ -z "$URL" ]]; then
    echo "Error: URL required"
    echo ""
    help
    exit 1
fi

# Set download directory
DOWNLOAD_DIR="${DOWNLOAD_DIR:-$DEFAULT_DIR}"

# Expand a leading tilde (paths are not shell-evaluated by the rofi launcher)
case "$DOWNLOAD_DIR" in
    "~")     DOWNLOAD_DIR="$HOME" ;;
    "~/"*)   DOWNLOAD_DIR="$HOME/${DOWNLOAD_DIR#\~/}" ;;
esac

if ! mkdir -p "$DOWNLOAD_DIR"; then
    echo "Error: Cannot create download directory: $DOWNLOAD_DIR"
    echo ""
    help
    exit 1
fi

# Define full path for the archive file inside the download directory
ARCHIVE_PATH="$DOWNLOAD_DIR/$ARCHIVE_FILE"


# yt-dlp options
OPTS=(
    --extract-audio
    --audio-format mp3
    --audio-quality 0
    --output "$DOWNLOAD_DIR/%(title)s.%(ext)s"
    --embed-thumbnail
    --add-metadata
    --download-archive "$ARCHIVE_PATH"
)

[[ "$PLAYLIST" == false ]] && OPTS+=(--no-playlist)

# Download
yt-dlp "${OPTS[@]}" "$URL" && \
    echo -e "\e[33m✓ Downloaded to $DOWNLOAD_DIR\e[0m"
