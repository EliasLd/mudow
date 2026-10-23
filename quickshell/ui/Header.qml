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

        // Theme toggle: shows the mode you will switch to. Tab-reachable
        // and key-activatable like the rest of the form.
        Rectangle {
            id: themeButton

            activeFocusOnTab: true
            border.width: activeFocus ? 2 : 0
            border.color: Theme.tokens.primary
            Keys.onReturnPressed: Preferences.setTheme(Theme.dark ? "light" : "dark")
            Keys.onEnterPressed: Preferences.setTheme(Theme.dark ? "light" : "dark")
            Keys.onSpacePressed: Preferences.setTheme(Theme.dark ? "light" : "dark")

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
                onClicked: {
                    themeButton.forceActiveFocus();
                    Preferences.setTheme(Theme.dark ? "light" : "dark");
                }
            }
        }

        // Close. Esc covers the same action anywhere in the window; this
        // keeps the button reachable in the tab chain regardless.
        Rectangle {
            id: closeButton

            activeFocusOnTab: true
            border.width: activeFocus ? 2 : 0
            border.color: Theme.tokens.primary
            Keys.onReturnPressed: root.closeRequested()
            Keys.onEnterPressed: root.closeRequested()
            Keys.onSpacePressed: root.closeRequested()

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
                onClicked: {
                    closeButton.forceActiveFocus();
                    root.closeRequested();
                }
            }
        }
    }
}