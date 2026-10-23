# mudow

A simple and modern set of tools to download YouTube videos or playlists as mp3 — from your terminal, with a Rofi menu, or with a quickshell desktop overlay.

![Usage demo](./assets/demo.gif)

---

## Overview

This repository provides three complementary tools:

### `mudow` (Music Downloader)

- **A minimal command-line wrapper around [yt-dlp](https://github.com/yt-dlp/yt-dlp)** to quickly download YouTube videos and playlists as high quality mp3s.
- Usable universally from any terminal, or in scripts.
- Specify a URL, a destination folder, and whether you want a playlist or a single video.

Example:
```sh
mudow https://youtube.com/watch?v=xxxxxxx
mudow --playlist https://youtube.com/playlist?list=xxxxxxx
mudow --path ~/Music/myfolder https://youtube.com/watch?v=xxxxxxx
```

Downloads land in `~/Music/<YYYY-MM-DD>-music` by default — a new folder per day. Each folder keeps an `archive.txt` download log, so re-running a previously downloaded URL into the same folder won't fetch it again.

*Requires: [`yt-dlp`](https://github.com/yt-dlp/yt-dlp) installed on your system (which itself needs `ffmpeg` to extract and convert audio).*

---

### The Rofi menu

- **A fully customizable graphical menu built with [Rofi](https://github.com/davatorium/rofi)**, serving as an intuitive interface to `mudow`.
- Select your URL, destination, and type (video/playlist) directly via shortcut or keybind (perfect for Hyprland/sway/wayland workflows).
- Uses a clean One Dark theme and supports direct clipboard paste and user interaction.
- Easily tweak appearance, keybinds, colors through the included Rofi style configs.

*Requires: [`rofi`](https://github.com/davatorium/rofi) installed on your system (along with `mudow`), `libnotify` (`notify-send`) for notifications, and a [Nerd Font](https://www.nerdfonts.com/) for the menu icons.*

---

### `mudow-gui` (Quickshell GUI Music Downloader)

- **A single-window desktop overlay built with [Quickshell](https://quickshell.outfoxxed.me)**, driving the same `mudow` command from a compact centered dialog with a One dark/light theme.
- URL field with direct clipboard paste, a video/playlist segmented selector, an optional destination override, and a live preview of the exact command that will run.
- **Fire-and-forget downloads**: submitting hides the window immediately and the download keeps running in the background — results arrive as desktop notifications, with the same copies as the Rofi menu.
- Small snappy animations (spring pop on open, cross-fade when toggling between the dark and light palettes), and preferences (theme, last destination) persist between sessions.

*Requires: [`quickshell`](https://quickshell.outfoxxed.me) 0.3+ (a Wayland compositor implementing `wlr-layer-shell`, e.g. Hyprland/sway), `mudow`, and a [Nerd Font](https://www.nerdfonts.com/) for the icons.*

---

## Why three tools?

- `mudow` is **universal**: works everywhere bash works, no GUI required.
- The Rofi menu brings the same features in a beautiful, integrated visual menu that's ideal for desktop environments and workflow automation.
- `mudow-gui` is the same flow as a **desktop overlay dialog** — one compact window, dark/light themes, fire-and-forget notifications, zero terminal interaction.

---

## Installation

Simply run the installation script

```sh
./install.sh
```

> [!NOTE]
> Maybe you don't use rofi or Arch (**btw**) and you just want to install mudow to use it in your terminal, and it's fine!
You can specify `--mudow-only` to install just the CLI, or pick what you want with `--rofi-only`, `--quickshell-only`, `--no-rofi` and `--no-quickshell`.

Depending on what options are used, the script will:
- Install `mudow` globally (`/usr/bin/mudow`)
- Copy the Rofi menu and its themes to `~/.config/rofi/mudow`
- Copy the quickshell GUI config to `~/.config/quickshell/mudow`
- Install the GUI launcher globally (`/usr/bin/mudow-gui`)
- Let you launch the Rofi interface with `~/.config/rofi/mudow/launch.sh`, or the GUI with `mudow-gui`  
  (optionally, bind either to a key combo in your WM!)

---

## Requirements

- [`yt-dlp`](https://github.com/yt-dlp/yt-dlp) (for actual downloading and conversion)
- `ffmpeg` (needed by `yt-dlp` to extract and convert audio, and embed thumbnails)
- [`rofi`](https://github.com/davatorium/rofi) (only needed for the Rofi launcher)
- [`quickshell`](https://quickshell.outfoxxed.me) (only needed for the quickshell GUI)
- `libnotify` (`notify-send`, needed for the launchers' notifications)

If on Arch, these are available with pacman and AUR:

```bash
pacman -S yt-dlp ffmpeg rofi libnotify quickshell
# Or with AUR, yay for example
yay -S yt-dlp ffmpeg rofi libnotify quickshell

# Nerd Font, used for the icons in both launchers (JetBrains Mono recommended)
pacman -S ttf-jetbrains-mono-nerd
```

---

## Customization

The menu style and launcher are fully hackable!  
Change colors, rounding, position, font, etc. in `~/.config/rofi/mudow/style.rasi`  
Edit `launch.sh` to fit your workflow.

The quickshell GUI is equally hackable: the dark/light palette, typography, shape and motion tokens all live in `~/.config/quickshell/mudow/config/Theme.qml`, and each part of the window is a small, editable QML file under `~/.config/quickshell/mudow/ui/`.