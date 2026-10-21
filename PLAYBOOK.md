# PLAYBOOK — rofi-music-dl

> Complete knowledge base of the codebase, gathered by full investigation of every file, the git history, and the README. Intended as the reference document for any future work on this project (quickshell port, yt-dlp wrapper feature expansion, refactors).

---

## 1. Project identity

| Field | Value |
|---|---|
| Name | **rofi-music-dl** (repo) / **mudow** (core tool) |
| Author / Owner | EliasLd (MIT License, © 2026) |
| Remote | `git@github.com:EliasLd/rofi-music-dl.git` |
| Head of `main` | `f716217` — "Merge pull request #6 … feat/archive_file" |
| Purpose | Wrapper around **yt-dlp** to download YouTube videos/playlists as **mp3** into a dedicated directory, exposed via (a) a CLI (`mudow`) and (b) a Rofi GUI menu |
| Origin story | Personal tool by the author at the start; ended up used by other people → maintainability and polish now matter |
| Language(s) | 100% Bash (scripts) + Rofi rasi (QML/QS config) |
| Size | Tiny: 3 shell scripts (~240 lines total), 2 rasi files, 1 GIF asset |

**Naming trivia:** `mudow` = **MU**sic + "**DOW**nload" (renamed from an earlier generic name in commit `16c24bc`).

---

## 2. Repository layout

```
rofi-music-dl/
├── mudow.sh              # Core CLI: yt-dlp wrapper (the "engine")
├── install.sh            # Installer for mudow (global) and/or rofi config
├── rofi/
│   ├── launch.sh         # Rofi GUI: 4-step dmenu flow → shells out to mudow
│   ├── style.rasi        # One Dark theme for the rofi windows
│   └── colors/
│       └── one-dark.rasi # Standalone One Dark palette (currently UNUSED by style.rasi)
├── assets/
│   └── demo.gif          # README demo (~776 KB)
├── LICENSE               # MIT
├── README.md             # Public-facing docs
└── PLAYBOOK.md           # This file
```

**Not present** (worth knowing / possible future additions): no `.gitignore`, no CI, no Makefile, no shellcheck config, no version tags, no uninstall script, no tests.

---

## 3. Architecture & data flow

```
                    ┌──────────────────────────────┐
  terminal ────────►│         mudow.sh             │──► yt-dlp ─► ffmpeg ─► mp3
                    │ (parse args, build OPTS,     │
                    │  mkdir, download-archive)    │
                    └──────────────────────────────┘
                                ▲
                    ┌───────────┴──────────────────┐
  rofi keybind ────►│        rofi/launch.sh        │
                    │ 1. ask URL      (rofi dmenu) │
                    │ 2. ask dest     (rofi dmenu) │
                    │ 3. ask type     (rofi dmenu) │
                    │ 4. confirm      (rofi dmenu) │
                    │ 5. eval "$CMD"  + notify-send│
                    └──────────────────────────────┘
                    install.sh copies mudow.sh → /usr/bin/mudow
                    install.sh copies rofi/* → ~/.config/rofi/rofi-music-dl/
```

Two independent front ends to one engine:
- **Terminal users** call `mudow` directly.
- **Desktop users** go through `launch.sh`, which only *builds an argument string* and `eval`s it — all real work stays in `mudow`. Keep this boundary when refactoring: the quickshell port should do the same (compose argv for `mudow`, don't reimplement download logic).

---

## 4. Component deep-dive

### 4.1 `mudow.sh` (85 lines) — the engine

Shebang `#!/usr/bin/env bash`, no `set` flags, no functions except `help`.

**Configuration (top of file):**
- `DEFAULT_DIR="$HOME/Music/$(date +%F)-music"` → a *new date-stamped folder per day* (e.g. `~/Music/2026-10-21-music`). This is the single most opinionated default in the project.
- `ARCHIVE_FILE="archive.txt"` → yt-dlp download-archive written **inside the download dir**.

**CLI surface:**
```
mudow [OPTIONS] URL
  -p, --path DIR     download dir (default: ~/Music/<today>-music)
  -P, --playlist     download entire playlist
  -h, --help
```

**Arg parsing quirks:**
- Hand-rolled `while [[ $# -gt 0 ]]` + `case` loop (no `getopts`).
- Positional arg: *any* unrecognized token is treated as `URL` (last one silently wins if several are given — no array of URLs).
- `-p` consumes the next token unconditionally: if `--path` is given last without a value, `$2` is empty and `shift 2` fails; the empty-URL check at the end is the only guard.
- No validation that the URL looks like a URL at all.

**Behavior:**
1. Validates URL non-empty, else prints error + help, exit 1.
2. `mkdir -p` the download dir.
3. Builds `OPTS` array (properly quoted, arrays are used correctly):
   ```bash
   --extract-audio --audio-format mp3 --audio-quality 0
   --output "$DOWNLOAD_DIR/%(title)s.%(ext)s"
   --embed-thumbnail --add-metadata
   --download-archive "$ARCHIVE_PATH"
   ```
4. If *not* playlist mode → appends `--no-playlist` (so a playlist URL yields only the linked video). Playlist mode = simply *lack* of `--no-playlist`; yt-dlp downloads all entries.
5. Runs `yt-dlp "${OPTS[@]}" "$URL"`, and on success prints a yellow `✓ Downloaded to $DOWNLOAD_DIR` (bash `echo -e` ANSI escape).

**yt-dlp semantics in play (reference for future features):**
- `--audio-quality 0` = best VBR mp3; requires ffmpeg/ffprobe on PATH (hidden dependency, see §6).
- `--embed-thumbnail` embeds cover art into the mp3.
- `--add-metadata` writes ID3 tags from YouTube metadata.
- Download-archive semantics: yt-dlp records **video IDs** in `archive.txt`; re-running the same URL into the *same directory* skips already-downloaded entries. Since the default dir is date-stamped, archives are effectively *per-day* — re-downloading on another day into a fresh folder will re-download everything (design decision to revisit: global archive vs per-dir).

### 4.2 `rofi/launch.sh` (57 lines) — the GUI

A self-contained multi-step wizard; each step is a *separate* `rofi -dmenu` invocation, all sharing the same theme.

**Hardcoded paths:** theme = sibling `style.rasi` (resolved via `BASH_SOURCE`, good), mudow = `/usr/bin/mudow` (matches install.sh target).

**Flow:**
1. **Guard:** if `/usr/bin/mudow` is not executable → `rofi -e "Error: mudow not found in ~/usr/bin/"`, exit 1.
2. **URL prompt** (`-p "YouTube URL: "`, `-mesg "Paste the YouTube video or playlist URL"`). Empty → exit 0 (cancel).
3. **Destination prompt** (optional). `-mesg` shows the today's default dir. Empty → mudow default.
4. **Type picker:** `echo -e " Single video\n󰉍 Playlist" | rofi -dmenu -selected-row 0` (Nerd Font glyphs). Empty → exit 0.
5. **Command build:** string concatenation — `CMD="$YT_MUSIC_DL"; [[ -n "$DEST" ]] && CMD="$CMD -p $DEST"; [[ "$TYPE" == "󰉍 Playlist" ]] && CMD="$CMD -P"; CMD="$CMD $URL"`.
6. **Confirmation:** shows `Command: $CMD` passed through `escape_markup()` (escapes `& < >` for rofi pango markup), Download / Cancel list.
7. **Execution:** `notify-send "Starting download..."` → `eval "$CMD" || notify-send "Failed!"`.

**Rofi flags used** (must be replicated in the quickshell port): `-dmenu`, `-p` (prompt), `-mesg` (footer help text), `-theme` (per-invocation), `-selected-row 0`, `-e` (error popup), plus markup in messages and Nerd Font icons.

### 4.3 `rofi/style.rasi` — the theme

- `configuration` block: JetBrains Mono Nerd Font 14, no icons, history enabled, no sidebar.
- Defines the **One Dark palette inline** (bg0–bg4, accent colors, greys).
- Window: 700 px wide, centered, 12 px radius, 2 px blue border, 32 px padding, real transparency.
- `listview { lines: 2; }` — sized exactly for the 2-option menus (type / confirm).
- Elements: rounded 8 px cards; selected = blue bg with dark text.
- **Import structure note:** `style.rasi` does **not** import `colors/one-dark.rasi` (no `import`/`@theme` reference anywhere). The palette is copy-pasted. `colors/one-dark.rasi` is currently **dead weight** except as a reference palette — a divergence risk if one is edited and not the other. (install.sh copies it anyway.)

### 4.4 `rofi/colors/one-dark.rasi` — unused palette file

Canonical One Dark variables (`bg0..bg4`, accents, `selected @bg3`, `active @blue`, `urgent @red`). See note above; either wire it into `style.rasi` or remove it.

### 4.5 `install.sh` (99 lines)

- ANSI-colored output (RED/GREEN/YELLOW/BLUE).
- Flags: `--mudow-only|-m`, `--rofi-only|-r`, `--help|-h`. **Unknown flags are silently shifted away** (no error).
- `install_script()`: if `/usr/bin/mudow` exists → interactive y/N replace prompt; else `sudo cp` + `chmod +x`.
- `copy_rofi_config()`: `mkdir -p ~/.config/rofi/rofi-music-dl`, then per-entry loop over `rofi/*` — `cp -r` for dirs, `cp` for files.
- Prints a summary + contextual notes depending on what was installed (`--rofi-only` note ends with a joke "(why?)").

### 4.6 `README.md`

Public docs: overview of the two tools, usage examples, `./install.sh` / `--mudow-only`, requirements (yt-dlp, rofi), customization pointer (~/.config path, edit launch.sh). Accurate but incomplete — see gaps in §7.

---

## 5. Runtime walkthrough (happy path)

1. User binds `~/.config/rofi/rofi-music-dl/launch.sh` to a key (e.g. Hyprland: `bind = $mainMod, M, exec, ~/.config/rofi/rofi-music-dl/launch.sh`).
2. Paste URL → press Enter. Skip destination (empty) → default dir. Pick `󰉍 Playlist`. Confirm `Download`.
3. `notify-send` "Starting download…" appears; `eval` runs `/usr/bin/mudow -P <URL>`.
4. In the background: `mkdir ~/Music/2026-10-21-music`, yt-dlp extracts audio → mp3 (best quality), embeds thumbnail, writes tags, appends IDs to `archive.txt` in that folder.
5. On yt-dlp failure → "Failed!" notification. On success → *nothing visible* (mudow's success message goes to stdout nobody sees — see issue #4).

Files produced: `~/Music/<date>-music/<Video Title>.mp3` (+ `archive.txt`).

## 6. Dependency matrix

| Dependency | Needed by | Status |
|---|---|---|
| `bash` | everything | required |
| `yt-dlp` | mudow.sh | required, documented in README |
| `ffmpeg`/`ffprobe` | yt-dlp (`--extract-audio`, `--embed-thumbnail`) | **required, NOT documented** — hidden dependency |
| `rofi` | launch.sh, style | required for GUI, documented |
| `notify-send` (libnotify) | launch.sh | **required for GUI, NOT documented** |
| Nerd Font (JetBrains Mono Nerd Font) | launch.sh glyphs, style.rasi font | **required, NOT documented** |
| `sudo` | install.sh (mudow install) | required |
| coreutils (`date` used everywhere) | mudow.sh, launch.sh | required |

Arch-specific notes: the README mentions pacman/AUR but nothing is distro-specific in the code; install to `/usr/bin` may be inappropriate on some distros (`/usr/local/bin` is the safer convention).

---

## 7. Known issues, bugs & technical debt

Numbered for easy reference in commits/discussions.

**Status (2026-10-21):** items 1–4, 6, 10 fixed; 5 resolved (palette imported by `style.rasi`); 7 mostly fixed (safe flag handling + single-URL enforcement; URL format validation intentionally deferred to phase 2); 11 fixed in the README (except uninstall, still absent). Still open: 8, 9, 12 (partial), 13, 14.

1. **`eval` + unquoted concatenation** (`launch.sh:40-43,56`): `DEST` and `URL` are interpolated raw into `CMD` then `eval`ed. Paths with spaces break (`-p ~/My Music`), and shell metacharacters in a pasted URL can execute arbitrary commands. **Fix direction:** build a bash array `CMD=(mudow -p "$DEST" [-P] "$URL")` and `exec "${CMD[@]}"` — no eval at all.
2. **`cp -r` re-install nests directories** (`install.sh:65`): re-running the installer when `~/.config/rofi/rofi-music-dl/colors/` already exists produces `…/colors/colors/…` (standard `cp -r` behavior). **Fix:** `rm -rf` the target (or `cp -rT`, or rsync `--delete`).
3. **Error message typo** (`launch.sh:13`): `~/usr/bin/` should be `/usr/bin/`.
4. **No success notification** (`launch.sh:54-56`): only "starting" and "failed" are notified; when launched from a keybind mudow's `✓ Downloaded…` line is invisible. **Fix:** capture exit status and notify on success (ideally with folder path).
5. **Dead palette file** (`rofi/colors/one-dark.rasi`): not imported by `style.rasi`; palette duplicated inline → divergence risk.
6. **Brittle type matching** (`launch.sh:42`): compare against the exact Nerd-Font string `"󰉍 Playlist"`; any glyph/font mismatch silently degrades to single-video mode.
7. **mudow arg parsing gaps** (`mudow.sh:33-52`): `-p` without value corrupts parsing (`shift 2` out of range); multiple URLs silently take the last; no URL sanity check; unknown flags become "URLs".
8. **No cancellation/timeout for the blocking download** in the GUI path — no progress feedback, and a long playlist blocks with only the start notification.
9. **Per-directory archive** (`mudow.sh:4-5,67`): date-stamped default dir + per-dir `archive.txt` means "resume/retry" only works within the same day's folder. Possibly intended, possibly a footgun — decide explicitly (global archive file vs per-dir).
10. **install.sh silent flag gobbling** (`install.sh:31-34`): `*) shift` swallows typos instead of erroring.
11. **Docs gaps in README**: undocumented `--rofi-only`, hidden deps (ffmpeg, notify-send, nerd font), `archive.txt` behavior, default-dir date-stamping, no uninstall instructions.
12. **Hygiene**: no `.gitignore` (nothing generates yet, but coming), no CI, no shellcheck lint, no version tags; `/usr/bin` install path instead of `/usr/local/bin`.
13. **No `set -euo pipefail`** in any script — failures inside the install/copy loops proceed silently.
14. **Blocking confirm-flow UX**: every step is a separate full rofi window; fine for 4 steps, but a quickshell port can do better in one surface.

---

## 8. Conventions observed (keep following these)

- **Bash style:** `#!/usr/bin/env bash`, 4-space indent, lowercase snake_case vars for config (`DOWNLOAD_DIR`, uppercase for globals), lowercase for locals; `[[ ]]` (bash-only, no POSIX pretense); arrays for command building (mudow does it right — launch.sh doesn't).
- **UX copy:** short lowercase prompts (`"YouTube URL: "`), emoji/glyph-prefixed choices, ANSI color in CLI output (`✓ …` yellow), `[OK]/[WARN]/[SKIP]` tags in installer.
- **Theme:** One Dark palette everywhere (`#282c34` family, `#61afef` blue accent), JetBrains Mono Nerd Font, rounded cards, 700 px window.
- **Commits:** conventional-commit-ish but inconsistent (`feat(mudow): enable archive file writing` vs `Update install script…`); branches `feat/*`, `documentation`, PR-merge-driven flow on `main`. Small, focused PRs.
- **Install targets:** `/usr/bin/mudow` (global binary), `~/.config/rofi/rofi-music-dl/` (user config, launch entry point).

---

## 9. Historical context (git log synthesis)

Development order (oldest → newest):
1. `Initial commit` → base music downloader script, arg parsing (`8e9a4dc`) → options & validation (`54e89ab`).
2. Renamed utility to **mudow** (`16c24bc`), One Dark theme (`057dd54`).
3. Rofi feature branch: rasi style, launch script, context notifications (`701618f`…`7932aae`).
4. Installation script branch, then docs (`93132c4`, `9ffd047`, MIT license).
5. Latest functional change: **archive file support** (`518f226`, PR #6) — added `--download-archive` writing `archive.txt` into the download dir.

**Implication:** the yt-dlp wrapper has grown organically by one feature at a time; the "engine" boundary (§3) was preserved throughout. The next phase (quickshell) is the first *new frontend* since rofi → the playbook's architecture map is the blueprint for it.

---

## 10. Roadmap (as stated by the owner)

### Phase 1 — Quickshell config (next immediate task)
Add a quickshell (QML) config as the modern replacement frontend for the rofi menu.

**Design (owner decision, 2026-10-21):**
- **Single window, all parameters at once:** URL input, destination, video/playlist mode and the download action live together on one surface — a direct window, not a multi-step wizard à la rofi.
- **Dark / light colorscheme:** two palette variants of the current One Dark look, switchable; no deeper theming system beyond that.
- Keep the thin-frontend rule (§3): quickshell composes a proper argv for `mudow` (safe argv building fixed in `fix(rofi)`) and spawns it — no yt-dlp logic in QML.
- Keep the UX essentials from the rofi flow: mudow path guard surfaced in the UI, cancellation at any point with no side effects, and start / success / failure notifications via `notify-send`.

### Phase 2 — More flexible & complete yt-dlp wrapping (after phase 1)
Owner wants a "more flexible and complete experience on yt-dlp wrapping". Candidate directions surfaced during analysis (subject to owner prioritization):
- Video (non-audio) download mode + format/quality selection (today: mp3-only).
- Multiple URLs / batch input; URL validation; better arg parsing (`getopts` or arrays).
- Playlist granularity (pick entries), chapter/split options, sponsorblock, subsections.
- Config file support (persistent default dir, quality, archive strategy) instead of hardcoded constants at top of mudow.sh.
- Global vs per-dir archive decision (issue #9); richer output templates; filename sanitization options.
- Progress reporting channel for GUIs (mudow could expose yt-dlp progress in a machine-readable way for quickshell/rofi progress bars).

---

## 11. "Do not break" list (invariants)

- `mudow` CLI shape (`[OPTIONS] URL`, `-p`, `-P`, `-h`) — README users depend on it.
- Install locations: `/usr/bin/mudow`, `~/.config/rofi/rofi-music-dl/launch.sh`.
- Default download dir convention: `~/Music/<YYYY-MM-DD>-music`.
- mudow prints a colored success line and exits non-zero on yt-dlp failure.
- The rofi/quickshell frontends remain thin: no yt-dlp logic outside mudow.