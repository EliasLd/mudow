pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config

// TYPE group: video-vs-playlist segmented control with a sliding pill.
ColumnLayout {
    id: root

    property bool playlist: false

    opacity: enabled ? 1 : 0.45
    Behavior on opacity {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easingCubic }
    }

    spacing: 6

    Text {
        text: "TYPE"
        color: Theme.tokens.fgMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall - 1
        font.weight: 600
        font.letterSpacing: 1.2
    }

    Rectangle {
        id: track

        Layout.fillWidth: true
        implicitHeight: 40
        radius: Theme.radius
        color: Theme.tokens.surfaceAlt

        // Sliding selection pill.
        Rectangle {
            id: pill

            property int index: root.playlist ? 1 : 0

            x: 3 + index * (track.width / 2 - 3)
            width: track.width / 2 - 6
            height: track.height - 6
            anchors.verticalCenter: parent.verticalCenter
            radius: Theme.radiusSmall
            color: Theme.tokens.primary
            Behavior on x {
                NumberAnimation {
                    duration: Theme.duration
                    easing.type: Theme.easingQuart
                }
            }
        }

        // Video segment
        Item {
            id: videoSegment

            activeFocusOnTab: true
            width: track.width / 2
            height: parent.height

            // Keyboard-activatable: Return, keypad Enter or Space select;
            // Right hops to the playlist segment.
            Keys.onReturnPressed: root.playlist = false
            Keys.onEnterPressed: root.playlist = false
            Keys.onSpacePressed: root.playlist = false
            Keys.onRightPressed: playlistSegment.forceActiveFocus()

            MouseArea {
                id: videoMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.playlist = false;
                    videoSegment.forceActiveFocus();
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: "\uF008"
                    color: !root.playlist ? Theme.tokens.onPrimary : Theme.tokens.fgMuted
                    Behavior on color {
                        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easingCubic }
                    }
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall + 1
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Single video"
                    color: !root.playlist ? Theme.tokens.onPrimary : Theme.tokens.fg
                    Behavior on color {
                        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easingCubic }
                    }
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: !root.playlist ? 600 : 500
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Focus ring: primary on the unselected half, onPrimary so it
            // stays visible against the filled selected half.
            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: Theme.radiusSmall
                color: "transparent"
                border.width: 2
                border.color: videoSegment.activeFocus
                    ? (root.playlist ? Theme.tokens.onPrimary : Theme.tokens.primary)
                    : "transparent"
                Behavior on border.color {
                    ColorAnimation {
                        duration: Theme.durationFast
                        easing.type: Theme.easingCubic
                    }
                }
            }
        }

        // Playlist segment
        Item {
            id: playlistSegment

            activeFocusOnTab: true
            x: track.width / 2
            width: track.width / 2
            height: parent.height

            // Keyboard-activatable; Left hops back to the video segment.
            Keys.onReturnPressed: root.playlist = true
            Keys.onEnterPressed: root.playlist = true
            Keys.onSpacePressed: root.playlist = true
            Keys.onLeftPressed: videoSegment.forceActiveFocus()

            MouseArea {
                id: playlistMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.playlist = true;
                    playlistSegment.forceActiveFocus();
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: "\uF03A"
                    color: root.playlist ? Theme.tokens.onPrimary : Theme.tokens.fgMuted
                    Behavior on color {
                        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easingCubic }
                    }
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall + 1
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Playlist"
                    color: root.playlist ? Theme.tokens.onPrimary : Theme.tokens.fg
                    Behavior on color {
                        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easingCubic }
                    }
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: root.playlist ? 600 : 500
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Focus ring: primary on the unselected half, onPrimary so it
            // stays visible against the filled selected half.
            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: Theme.radiusSmall
                color: "transparent"
                border.width: 2
                border.color: playlistSegment.activeFocus
                    ? (root.playlist ? Theme.tokens.onPrimary : Theme.tokens.primary)
                    : "transparent"
                Behavior on border.color {
                    ColorAnimation {
                        duration: Theme.durationFast
                        easing.type: Theme.easingCubic
                    }
                }
            }
        }
    }
}