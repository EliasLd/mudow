pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config

// Window header: brand left; theme toggle + close right.
Rectangle {
    id: root

    signal closeRequested()

    implicitHeight: 32
    color: "transparent"

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            text: "\uF001"
            color: Theme.tokens.primary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 4
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: "mudow"
            color: Theme.tokens.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: 600
            font.letterSpacing: 0.5
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        // Theme toggle: shows the mode you will switch to.
        Rectangle {
            id: themeButton

            implicitWidth: 28
            implicitHeight: 28
            radius: Theme.radiusSmall
            color: themeMouse.pressed
                ? Theme.tokens.border
                : themeMouse.containsMouse ? Theme.tokens.surfaceAlt : "transparent"
            Behavior on color {
                ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easingCubic }
            }

            Text {
                anchors.centerIn: parent
                text: Theme.dark ? "\uF185" : "\uF186"
                color: Theme.tokens.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall + 2
            }

            MouseArea {
                id: themeMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Preferences.setTheme(Theme.dark ? "light" : "dark")
            }
        }

        // Close
        Rectangle {
            id: closeButton

            implicitWidth: 28
            implicitHeight: 28
            radius: Theme.radiusSmall
            color: closeMouse.pressed
                ? Theme.tokens.danger
                : closeMouse.containsMouse ? Theme.tokens.surfaceAlt : "transparent"
            Behavior on color {
                ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easingCubic }
            }

            Text {
                anchors.centerIn: parent
                text: "\uF00D"
                color: closeMouse.pressed ? Theme.tokens.onPrimary : Theme.tokens.fg
                Behavior on color {
                    ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easingCubic }
                }
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall + 2
            }

            MouseArea {
                id: closeMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeRequested()
            }
        }
    }
}