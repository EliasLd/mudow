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

            width: track.width / 2
            height: parent.height

            MouseArea {
                id: videoMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.playlist = false
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
        }

        // Playlist segment
        Item {
            id: playlistSegment

            x: track.width / 2
            width: track.width / 2
            height: parent.height

            MouseArea {
                id: playlistMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.playlist = true
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
        }
    }
}