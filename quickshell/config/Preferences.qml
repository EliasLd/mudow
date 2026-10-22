pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io

// User preferences persisted to state.json (FileView + JsonAdapter store,
// saved on every change). Exposed read-only at the root; mutations go
// through setter functions so persistence is centralized.
Singleton {
    id: prefs

    FileView {
        id: store

        path: Quickshell.env("HOME") + "/.config/quickshell/rofi-music-dl/state.json"
        watchChanges: true
        atomicWrites: true
        // Absent file is the normal first-run state (defaults apply);
        // silence the read warning instead of spamming the log.
        printErrors: false
        onAdapterUpdated: store.writeAdapter()
        onFileChanged: store.reload()
        adapter: JsonAdapter {
            property string theme: "dark"
            property string lastDest: ""
        }
    }

    // The config directory is installed by install.sh, but the state
    // file's parent might not exist yet on a first dev run.
    Process {
        command: ["mkdir", "-p", Quickshell.env("HOME") + "/.config/quickshell/rofi-music-dl"]
        running: true
    }

    // Reactive, read-only view over the persisted adapter state.
    readonly property string theme: store.adapter.theme
    readonly property string lastDest: store.adapter.lastDest

    function setTheme(value: string): void {
        store.adapter.theme = value === "light" ? "light" : "dark";
    }

    function setLastDest(value: string): void {
        store.adapter.lastDest = value;
    }
}