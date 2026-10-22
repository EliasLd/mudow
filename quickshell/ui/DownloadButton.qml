pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config

// Submit pill: enabled once a URL is present. Pressing it starts the
// download fire-and-forget style — the window hides immediately and the
// result arrives as a notification (rofi-parity copies).
Rectangle {
    id: root

    signal clicked()

    required property bool allowed

    implicitHeight: 44
    radius: height / 2
    color: allowed ? Theme.tokens.primary : Theme.tokens.surfaceAlt
    Behavior on color {
        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easingCubic }
    }
    opacity: allowed ? 1 : 0.4
    Behavior on opacity {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easingCubic }
    }

    // Pressed feedback (scale) with a spring back.
    scale: pressMouse.pressed ? 0.98 : 1
    Behavior on scale {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easingQuart }
    }

    MouseArea {
        id: pressMouse

        anchors.fill: parent
        hoverEnabled: true
        enabled: root.allowed
        cursorShape: root.allowed ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }

    Row {
        anchors.centerIn: parent
        spacing: 10

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "\uF019"
            color: Theme.tokens.onPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall + 2
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Download"
            color: root.allowed ? Theme.tokens.onPrimary : Theme.tokens.fgMuted
            Behavior on color {
                ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easingCubic }
            }
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: 600
            font.letterSpacing: 0.5
        }
    }
}