pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config

// Muted preview of the command that will be handed to mudow.
// args is the exact array the Process will spawn: what you read here is
// what runs — a single source of truth between display and execution.
Text {
    id: root

    required property var args

    function quoteArg(arg) {
        if (arg === "")
            return "''";
        return /[\s'"]/.test(arg) ? "'" + arg.replace(/'/g, "'\\''") + "'" : arg;
    }

    Layout.fillWidth: true
    text: "→  " + args.map(quoteArg).join(" ")
    textFormat: Text.PlainText
    color: Theme.tokens.fgMuted
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeSmall
    elide: Text.ElideMiddle
    opacity: enabled ? 1 : 0.45
    Behavior on opacity {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easingCubic }
    }
}