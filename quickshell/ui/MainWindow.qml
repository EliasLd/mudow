pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.ui

// Overlay-style dialog: the layer-shell surface is deliberately anchored
// to every screen edge, which per the layer-shell spec stretches it across
// the screen. The surface is transparent — the visible body is a small,
// rounded card centered with Qt anchors, under a dim scrim that dismisses
// on outside click. An exclusive keyboard grab makes the form modal while
// it is open; submitting a download hides the window while the instance
// keeps the download running in the background (fire-and-forget).
PanelWindow {
    id: root

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    // Overlay layer above everything, exclusive keyboard while open.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "mudow-overlay"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    // Single source of truth for the mudow command: the on-screen
    // preview and the spawned process read this array.
    readonly property var commandArgs: {
        const dest = destCard.text.trim();
        const args = [Paths.mudowPath];
        if (dest !== "")
            args.push("-p", dest);
        if (typeSelector.playlist)
            args.push("-P");
        args.push(urlCard.text.trim());
        return args;
    }

    // Fire-and-forget download: while it runs the window stays hidden and
    // the instance outlives it, reporting through notifications.
    readonly property bool hasUrl: urlCard.text.trim() !== ""
    // Explicit state flag. Do NOT derive this from mudowProc.running:
    // bindings over a Process property set from script go stale on 0.3.2,
    // and a stale false here would terminate the instance right after
    // submit.
    property bool busy: false
    property string lastLine: ""

    function stripAnsi(line) {
        return line.replace(/\x1B\[[0-9;]*m/g, "");
    }

    // Same notification copy as rofi/launch.sh; delivered through the
    // desktop's notification daemon.
    function notify(icon, message) {
        Quickshell.execDetached([Paths.notifySendPath, "-a", "mudow", "-i", icon, "YouTube Download", message]);
    }

    // Submit: persist the destination, notify, spawn, hide. The busy flag
    // flips before the hide so the hide handler sees a running download
    // and lets it outlive the window. Every trigger funnels here — the
    // Download button (mouse or keyboard) and Enter in either field. An
    // empty URL shakes the source field instead of failing silently.
    function submit() {
        if (!root.hasUrl) {
            urlCard.shake();
            return;
        }
        if (root.busy || !Paths.mudowOk)
            return;
        root.busy = true;
        Preferences.setLastDest(destCard.text.trim());
        root.lastLine = "";
        mudowProc.command = root.commandArgs.slice();
        notify("download", "Starting download...");
        mudowProc.running = true;
        root.visible = false; // fire-and-forget: gone instantly
    }

    // Dismissal: only meaningful while the form is open (a download that
    // already started survives the window — see the hide handler).
    function requestClose() {
        if (!root.busy)
            root.visible = false;
    }

    // Transient visibility flaps fire while the config loads (and on
    // screen changes); a real dismissal cannot happen within 500ms, so
    // shutdown only acts once the settle timer armed the app.
    property bool appActive: false

    Timer {
        id: settleTimer

        interval: 500
        running: true
        onTriggered: {
            root.appActive = true;
            // Dismissed during the settle window? That was a real close
            // the hide handler skipped — shut down instead of leaving an
            // invisible instance blocking future -n launches. A download
            // already running (submitted within the window) stays alive.
            if (!root.visible && !root.busy)
                quitTimer.restart();
        }
    }

    onVisibleChanged: {
        // Use root.visible: this signal carries no argument on 0.3.2 (a
        // handler parameter reads undefined). busy hides are the
        // submitted window going away: the download outlives the form
        // and reports via notifications.
        if (!root.visible && root.appActive && !root.busy)
            quitTimer.restart();
    }

    // Small grace delay (lets the hide settle and persistence flush),
    // then the instance self-terminates so the next launch stays fresh.
    Timer {
        id: quitTimer

        interval: 500
        onTriggered: shutdown.running = true
    }

    Process {
        id: shutdown

        command: ["kill", "-TERM", String(Quickshell.processId)]
    }

    // mudow runs to completion on its own: on success parse the target
    // directory for the finish notification, on failure mirror rofi's
    // copy. Either way the instance then terminates itself.
    Process {
        id: mudowProc

        stdout: SplitParser {
            onRead: data => root.lastLine = root.stripAnsi(data)
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                const found = root.lastLine.match(/Downloaded to (.*)/);
                const dir = found ? found[1].trim() : "";
                notify("dialog-positive", dir !== "" ? "Download finished!\n" + dir : "Download finished!");
            } else {
                notify("dialog-error", "Failed!");
            }
            root.busy = false;
            quitTimer.restart();
        }
    }

    Shortcut {
        sequences: ["Esc"]
        onActivated: root.requestClose()
    }

    // ---- scrim + outside click dismiss ----
    Rectangle {
        id: backdrop

        anchors.fill: parent
        color: "#000000"
        opacity: 0 // driven by openAnimation
        Behavior on opacity {
            NumberAnimation { duration: Theme.duration; easing.type: Theme.easingQuart }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.requestClose()
        }
    }

    // ---- overlay card ----
    Rectangle {
        id: contentRoot

        anchors.centerIn: parent
        width: 550
        height: column.implicitHeight + 2 * 16

        radius: Theme.radius
        color: Theme.tokens.bg
        Behavior on color {
            ColorAnimation { duration: Theme.duration; easing.type: Theme.easingQuart }
        }
        border.width: 1
        border.color: Theme.tokens.border
        Behavior on border.color {
            ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easingCubic }
        }

        // Soft drop shadow, rendered on the card's buffer.
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 0.4
            shadowVerticalOffset: 2
            shadowOpacity: 0.4
            shadowColor: "#000000"
        }

        ColumnLayout {
            id: column

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 16
            }
            spacing: 10

            Header {
                Layout.fillWidth: true
                onCloseRequested: root.requestClose()
            }

            // Guard: the GUI composes argv for mudow; without it there is
            // nothing to drive.
            Text {
                visible: !Paths.mudowOk
                Layout.fillWidth: true
                text: "mudow not found — install mudow first (see README)"
                color: Theme.tokens.danger
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }

            UrlCard {
                id: urlCard

                Layout.fillWidth: true
                onSubmitted: root.submit()
            }

            TypeSelector {
                id: typeSelector

                Layout.fillWidth: true
            }

            DestinationCard {
                id: destCard

                Layout.fillWidth: true
                onSubmitted: root.submit()
            }

            CommandPreview {
                Layout.fillWidth: true
                args: root.commandArgs
            }

            DownloadButton {
                Layout.fillWidth: true
                allowed: root.hasUrl && Paths.mudowOk
                onClicked: root.submit()
            }
        }
    }

    // Open animation: scrim fade + card spring pop. Replays on hot
    // reload, which doubles as a live preview while developing.
    onWindowConnected: {
        openAnimation.restart();
        console.info("mudow window connected");
    }

    ParallelAnimation {
        id: openAnimation

        // Scrim fades in behind the card.
        NumberAnimation {
            target: backdrop
            property: "opacity"
            from: 0
            to: 0.35
            duration: Theme.duration
            easing.type: Theme.easingQuart
        }
        NumberAnimation {
            target: contentRoot
            property: "opacity"
            from: 0
            to: 1
            duration: Theme.duration
            easing.type: Theme.easingQuart
        }
        // Spring for the overlay pop.
        NumberAnimation {
            target: contentRoot
            property: "scale"
            from: 0.9
            to: 1
            duration: Theme.duration
            easing.type: Theme.easingBack
            easing.overshoot: 1.2
        }
    }
}