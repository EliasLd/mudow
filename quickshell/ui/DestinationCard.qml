pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.config

// DESTINATION group: optional directory override. Empty = use mudow's
// own default (announced in the placeholder). The last non-empty value is
// remembered on submit in Preferences. Enter in the field submits, exactly
// like the source field and the Download button.
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
        text: "DESTINATION"
        color: Theme.tokens.fgMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall - 1
        font.weight: 600
        font.letterSpacing: 1.2
    }

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
            anchors.rightMargin: field.text === "" ? 12 : 44
            verticalAlignment: TextInput.AlignVCenter

            color: Theme.tokens.fg
            placeholderTextColor: Theme.tokens.fgMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            background: Rectangle { color: "transparent" }
            selectByMouse: true
            onAccepted: root.submitted()
            placeholderText: Paths.defaultDirectory() + "  (default)"

            // The state file loads asynchronously, so construction-time
            // reads see defaults: seed the remembered value reactively
            // instead — it fills the field only while empty.
            Connections {
                target: Preferences
                function onLastDestChanged() {
                    if (field.text === "" && Preferences.lastDest !== "")
                        field.text = Preferences.lastDest;
                }
            }
        }

        // Reset to default (clear the override)
        Rectangle {
            visible: field.text !== ""
            implicitWidth: 26
            implicitHeight: 26
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            radius: Theme.radiusSmall
            color: resetMouse.pressed
                ? Theme.tokens.border
                : resetMouse.containsMouse ? Theme.tokens.surfaceAlt : "transparent"
            Behavior on color {
                ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easingCubic }
            }

            Text {
                anchors.centerIn: parent
                text: "\uF021"
                color: Theme.tokens.fgMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }

            MouseArea {
                id: resetMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Preferences.setLastDest("");
                    field.text = "";
                    field.forceActiveFocus();
                }
            }
        }
    }
}