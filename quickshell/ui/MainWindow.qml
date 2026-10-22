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

    // Dismissal: layer surfaces receive no close events, so the
    // visible->hidden transition drives the instance shutdown below.
    function requestClose() {
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
            // invisible instance blocking future -n launches.
            if (!root.visible)
                quitTimer.restart();
        }
    }

    onVisibleChanged: visible => {
        if (!visible && root.appActive)
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