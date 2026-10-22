pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

// Filesystem paths and external-tool availability for the whole config.
// Quickshell's `Singleton` root type is required to hold Process children.
Singleton {
    id: root

    // mudow CLI (see mudow.sh in the repo). Kept in one place so the
    // guard banner, command preview and spawned process can never diverge.
    readonly property string mudowPath: "/usr/bin/mudow"
    readonly property string notifySendPath: "/usr/bin/notify-send"
    readonly property string wlPastePath: "/usr/bin/wl-paste"

    // Availability probes (started on load, `test` exits 0/1 silently).
    property bool mudowOk: false
    property bool wlPasteOk: false

    // Mirrors mudow.sh DEFAULT_DIR: ~/Music/<YYYY-MM-DD>-music.
    function defaultDirectory(): string {
        const date = Qt.formatDate(new Date(), "yyyy-MM-dd");
        return Quickshell.env("HOME") + "/Music/" + date + "-music";
    }

    Process {
        command: ["test", "-x", root.mudowPath]
        running: true
        onExited: (exitCode, exitStatus) => {
            root.mudowOk = (exitCode === 0);
            console.info("mudow probe:", root.mudowPath, "=>", root.mudowOk);
        }
    }

    Process {
        command: ["test", "-x", root.wlPastePath]
        running: true
        onExited: (exitCode, exitStatus) => {
            root.wlPasteOk = (exitCode === 0);
            console.info("wl-paste probe:", root.wlPastePath, "=>", root.wlPasteOk);
        }
    }
}