pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import qs.config

// SOURCE group: section label + URL field with paste and clear actions.
// Enter in the field submits the download.
ColumnLayout {
    id: root

    property alias text: field.text
    signal submitted()

    opacity: enabled ? 1 : 0.45
    Behavior on opacity {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easingCubic }
    }

    spacing: 6

    Text {
        text: "SOURCE"
        color: Theme.tokens.fgMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall - 1
        font.weight: 600
        font.letterSpacing: 1.2
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 0

        Rectangle {
            id: card

            Layout.fillWidth: true
            implicitHeight: 40
            radius: Theme.radius
            color: Theme.tokens.surface
            border.width: 1
            border.color: field.activeFocus ? Theme.tokens.primary : Theme.tokens.border
            Behavior on border.color {
                ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easingCubic }
            }

            TextField {
                id: field

                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 64
                verticalAlignment: TextInput.AlignVCenter

                color: Theme.tokens.fg
                placeholderText: "Paste a YouTube URL…"
                placeholderTextColor: Theme.tokens.fgMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                background: Rectangle { color: "transparent" }
                selectByMouse: true
                onAccepted: root.submitted()

                // Focus the field on open: the overlay holds an exclusive
                // keyboard grab, so typing goes to the URL immediately.
                Component.onCompleted: field.forceActiveFocus()

                // Paste from the Wayland clipboard (wl-paste -n = no newline).
                Process {
                    id: pasteProbe

                    stdout: StdioCollector {
                        onStreamFinished: {
                            const value = text.trim();
                            if (value !== "")
                                field.text = value;
                        }
                    }
                }
            }

            RowLayout {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                // Paste
                Rectangle {
                    visible: Paths.wlPasteOk && field.text === ""
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: Theme.radiusSmall
                    color: pasteMouse.pressed
                        ? Theme.tokens.border
                        : pasteMouse.containsMouse ? Theme.tokens.surfaceAlt : "transparent"
                    Behavior on color {
                        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easingCubic }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "\uF0EA"
                        color: Theme.tokens.fgMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    MouseArea {
                        id: pasteMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            pasteProbe.command = [Paths.wlPastePath, "-n"];
                            pasteProbe.running = false;
                            pasteProbe.running = true;
                        }
                    }
                }

                // Clear
                Rectangle {
                    visible: field.text !== ""
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: Theme.radiusSmall
                    color: clearMouse.pressed
                        ? Theme.tokens.border
                        : clearMouse.containsMouse ? Theme.tokens.surfaceAlt : "transparent"
                    Behavior on color {
                        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easingCubic }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "\uF00D"
                        color: Theme.tokens.fgMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    MouseArea {
                        id: clearMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            field.text = "";
                            field.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }
}