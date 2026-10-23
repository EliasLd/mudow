#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
ROFI_CONFIG_DIR="$HOME/.config/rofi/mudow"
ROFI_SRC_DIR="$REPO_DIR/rofi"
QUICKSHELL_CONFIG_DIR="$HOME/.config/quickshell/mudow"
QUICKSHELL_SRC_DIR="$REPO_DIR/quickshell"

INSTALL_MUDOW=true
INSTALL_ROFI=true
INSTALL_QUICKSHELL=true

# --- Parse flags ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --mudow-only|-m)
            INSTALL_ROFI=false
            INSTALL_QUICKSHELL=false
            shift
            ;;
        --rofi-only|-r)
            INSTALL_MUDOW=false
            INSTALL_QUICKSHELL=false
            shift
            ;;
        --quickshell-only|-q)
            INSTALL_MUDOW=false
            INSTALL_ROFI=false
            shift
            ;;
        --no-rofi)
            INSTALL_ROFI=false
            shift
            ;;
        --no-quickshell)
            INSTALL_QUICKSHELL=false
            shift
            ;;
        --help|-h)
            echo -e "Usage: $0 [--mudow-only|-m] [--rofi-only|-r] [--quickshell-only|-q] [--no-rofi] [--no-quickshell]"
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}"
            echo -e "Usage: $0 [--mudow-only|-m] [--rofi-only|-r] [--quickshell-only|-q] [--no-rofi] [--no-quickshell]"
            exit 1
            ;;
    esac
done

if ! $INSTALL_MUDOW && ! $INSTALL_ROFI && ! $INSTALL_QUICKSHELL; then
    echo -e "${RED}Error: nothing to install${NC}"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}            mudow Installer            ${NC}"
echo -e "${BLUE}========================================${NC}\n"

# --- Install a script to /usr/bin (asks before replacing) ---
install_script() {
    local src="$1"
    local dest="$2"
    if [ -f "$dest" ]; then
        echo -e "${YELLOW}[WARN]${NC} $dest already exists."
        read -p "Wanna replace it? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}[SKIP]${NC} kept $dest"
            return
        fi
    fi
    sudo cp "$src" "$dest"
    sudo chmod +x "$dest"
    echo -e "${GREEN}[OK]${NC} Installed $(basename "$src") -> $dest"
}

# --- Copy a config tree (idempotent, merges into the destination) ---
copy_config_tree() {
    local src_dir="$1"
    local dest_dir="$2"
    mkdir -p "$dest_dir"
    for f in "$src_dir"/*; do
        # -rT merges the content instead of nesting if the destination dir exists
        if [ -d "$f" ]; then
            cp -rT "$f" "$dest_dir/$(basename "$f")"
        elif [ -f "$f" ]; then
            cp "$f" "$dest_dir/"
        fi
    done
    echo -e "${GREEN}[OK]${NC} Copied config to $dest_dir"
}

# --- One-time carry-over of state.json from the previous config dir ---
migrate_state() {
    local legacy_state="$HOME/.config/quickshell/rofi-music-dl/state.json"
    local dest_state="$QUICKSHELL_CONFIG_DIR/state.json"
    if [ ! -f "$dest_state" ] && [ -f "$legacy_state" ]; then
        cp "$legacy_state" "$dest_state"
        echo -e "${GREEN}[OK]${NC} Kept state.json from the previous config location"
    fi
}

# --- Installation process ---
STEPS=()
$INSTALL_MUDOW && STEPS+=(mudow)
$INSTALL_ROFI && STEPS+=(rofi)
$INSTALL_QUICKSHELL && STEPS+=(quickshell)
TOTAL=${#STEPS[@]}

STEP=0
if $INSTALL_MUDOW; then
    STEP=$((STEP + 1))
    echo -e "${BLUE}[$STEP/$TOTAL]${NC} Installing mudow.sh to /usr/bin/mudow..."
    install_script "$REPO_DIR/mudow.sh" "/usr/bin/mudow"
fi

if $INSTALL_ROFI; then
    STEP=$((STEP + 1))
    echo -e "\n${BLUE}[$STEP/$TOTAL]${NC} Installing the Rofi menu config..."
    copy_config_tree "$ROFI_SRC_DIR" "$ROFI_CONFIG_DIR"
fi

if $INSTALL_QUICKSHELL; then
    STEP=$((STEP + 1))
    echo -e "\n${BLUE}[$STEP/$TOTAL]${NC} Installing quickshell GUI config..."
    copy_config_tree "$QUICKSHELL_SRC_DIR" "$QUICKSHELL_CONFIG_DIR"
    migrate_state
    install_script "$REPO_DIR/mudow-gui.sh" "/usr/bin/mudow-gui"
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}       Finished installation! ${NC}"
echo -e "${GREEN}========================================${NC}\n"
echo -e "${YELLOW}Notes :${NC}"
if $INSTALL_MUDOW && $INSTALL_ROFI && $INSTALL_QUICKSHELL; then
    echo "  - mudow is available as a global command"
    echo "  - the Rofi menu config is under ~/.config/rofi/mudow"
    echo "  - quickshell GUI config is under ~/.config/quickshell/mudow"
    echo "  - launch the Rofi menu: ~/.config/rofi/mudow/launch.sh"
    echo "  - launch the GUI: mudow-gui"
    echo "  - you can symlink or set a keybind to either launcher if desired"
elif $INSTALL_MUDOW && $INSTALL_QUICKSHELL; then
    echo "  - mudow installed globally, GUI available as mudow-gui (no rofi)"
elif $INSTALL_MUDOW && $INSTALL_ROFI; then
    echo "  - mudow installed globally, no quickshell"
    echo "  - the Rofi menu config is under ~/.config/rofi/mudow"
    echo "  - launch: ~/.config/rofi/mudow/launch.sh"
elif $INSTALL_QUICKSHELL; then
    echo "  - quickshell GUI config installed (no mudow — the GUI needs it!)"
    echo "  - config is under ~/.config/quickshell/mudow; launch with mudow-gui"
elif $INSTALL_ROFI; then
    echo "  - only the Rofi menu config installed, no mudow (why?)"
elif $INSTALL_MUDOW; then
    echo "  - mudow installed globally, no frontends"
fi
echo -e ""