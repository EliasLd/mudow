pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import qs.config

// Central tokens: dark/light One palettes, typography, shape and motion.
// Components never hard-code colors, fonts or animation values.
//
// Motion signature: Easing.OutQuart, ~200ms, OutBack(1.2) for overlay pops.
QtObject {
    id: root

    readonly property bool dark: Preferences.theme !== "light"
    readonly property var tokens: dark ? darkTokens : lightTokens

    // Dark: the repo's One Dark identity (same palette as rofi/style.rasi).
    // Light: One Light variant, accents darkened for contrast on white.
    readonly property var darkTokens: ({
        bg: "#282c34",
        surface: "#2c313a",
        surfaceAlt: "#21252b",
        fg: "#abb2bf",
        fgMuted: "#5c6370",
        border: "#3e4451",
        primary: "#61afef",
        onPrimary: "#282c34",
        success: "#98c379",
        danger: "#e08c75"
    })

    readonly property var lightTokens: ({
        bg: "#fafafa",
        surface: "#ffffff",
        surfaceAlt: "#edeef2",
        fg: "#282c34",
        fgMuted: "#8a8e97",
        border: "#dcdde3",
        primary: "#2f7fd6",
        onPrimary: "#ffffff",
        success: "#528b1e",
        danger: "#b3401e"
    })

    // Typography
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13
    readonly property int fontSizeSmall: 11

    // Shape
    readonly property int radius: 10
    readonly property int radiusSmall: 6
    readonly property int radiusFull: 999

    // Motion (values in ms)
    readonly property int duration: 200
    readonly property int durationFast: 120
    readonly property int durationSlow: 350
    readonly property int easingQuart: Easing.OutQuart
    readonly property int easingCubic: Easing.OutCubic
    readonly property int easingBack: Easing.OutBack
}