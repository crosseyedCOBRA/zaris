import QtQuick

// Compact weather bar module - icon + temperature only, reusing
// WeatherService's already-fetched data (no new fetching logic here).
// WeatherWidget.qml is the fuller Control Center/calendar-flyout version
// (condition text, hi/lo, 5-day forecast) - too large for the bar.
Row {
    id: root

    property color textColor: "white"

    spacing: 4

    NText {
        text: WeatherService.haveData ? WeatherService.iconGlyphCurrent : ""
        color: root.textColor
        pointSize: Style.fontSizeL
    }

    NText {
        visible: WeatherService.haveData
        text: Math.round(WeatherService.temperatureF) + "°F"
        color: root.textColor
        pointSize: Style.fontSizeL
    }
}
