#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
ROFI_CONFIG_DIR="$HOME/.config/rofi/rofi-music-dl"
ROFI_SRC_DIR="$REPO_DIR/rofi"

INSTALL_MUDOW=true
INSTALL_ROFI=true

# --- Parse flags ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --mudow-only|-m)
            INSTALL_ROFI=false
            shift
            ;;
        --rofi-only|-r)
            INSTALL_MUDOW=false
            shift
            ;;
        --help|-h)
            echo -e "Usage: $0 [--mudow-only|-m] [--rofi-only|-r]"
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}"
            echo -e "Usage: $0 [--mudow-only|-m] [--rofi-only|-r]"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   mudow & Rofi Music DL Installer${NC}"
echo -e "${BLUE}========================================${NC}\n"

# --- Install mudow ---
install_script() {
    local src="$1"
    local dest="/usr/bin/mudow"
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
    echo -e "${GREEN}[OK]${NC} Installed mudow -> $dest"
}

# --- Copy Rofi config ---
copy_rofi_config() {
    mkdir -p "$ROFI_CONFIG_DIR"
    for f in "$ROFI_SRC_DIR"/*; do
        # -rT merges the content instead of nesting if the destination dir exists
        if [ -d "$f" ]; then
            cp -rT "$f" "$ROFI_CONFIG_DIR/$(basename "$f")"
        elif [ -f "$f" ]; then
            cp "$f" "$ROFI_CONFIG_DIR/"
        fi
    done
    echo -e "${GREEN}[OK]${NC} Copied Rofi menu configs to $ROFI_CONFIG_DIR"
}

# --- Installation process ---
if $INSTALL_MUDOW; then
    echo -e "${BLUE}[1/2]${NC} Installing mudow.sh to /usr/bin/mudow..."
    install_script "$REPO_DIR/mudow.sh"
fi

if $INSTALL_ROFI; then
    echo -e "\n${BLUE}[2/2]${NC} Installing Rofi Music DL config..."
    copy_rofi_config
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}       Finished installation! ${NC}"
echo -e "${GREEN}========================================${NC}\n"
echo -e "${YELLOW}Notes :${NC}"
if $INSTALL_MUDOW && $INSTALL_ROFI; then
    echo "  - mudow is available as a global command"
    echo "  - rofi-music-dl configs are under ~/.config/rofi/rofi-music-dl"
    echo "  - To launch: ~/.config/rofi/rofi-music-dl/launch.sh"
    echo "  - You can symlink or set a keybind to the launcher if desired"
    echo ""
elif $INSTALL_MUDOW; then
    echo "  - mudow installed globally, no Rofi"
elif $INSTALL_ROFI; then
    echo "  - Only rofi-music-dl config installed, no mudow (why?)"
fi
echo ""
