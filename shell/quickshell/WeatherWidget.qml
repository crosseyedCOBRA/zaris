import QtQuick

// Current-conditions weather display (icon, temperature+condition,
// location+hi/lo) plus a 5-day forecast row underneath - its own file
// since it's now used in two places (Control Center's own Weather
// section, and CalendarFlyout.qml's) rather than duplicated between
// them. All the actual data/fetching lives in WeatherService.qml; this is
// purely presentation. Every embedder sets `width:` explicitly (same
// contract as CalendarWidget.qml/AudioMixer.qml) - the forecast row below
// needs a real width to divide evenly across 5 day cells.
//
// The location line respects WeatherService.hideLocation (Settings'
// Profile tab "Hide location" toggle) - for anyone who doesn't want their
// city name visible in a panel that could end up in a screenshot or
// stream, the temperature/condition/hi-lo still shows, just not the place
// name itself.
Column {
    id: root

    property real iconPointSize: Style.fontSizeXXXL

    spacing: 12

    // Was `width: parent.width` (this Row left-aligned within its own
    // full-width bounds, since Row positions children starting at x: 0) -
    // centered as a group instead, sized to its own natural content width -
    // reported live as wanting everything in this widget centered, and
    // this was the one row not already centered/evenly distributed
    // (unlike the per-cell-centered forecast row below).
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12

        NText {
            text: WeatherService.haveData ? WeatherService.iconGlyphCurrent : ""
            color: Colors.blue
            pointSize: root.iconPointSize
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            NText {
                text: {
                    if (WeatherService.errorText !== "")
                        return "Weather unavailable"
                    if (!WeatherService.haveData)
                        return "Loading weather..."
                    return Math.round(WeatherService.temperatureF) + "°F  " + WeatherService.conditionTextCurrent
                }
                color: Colors.text
                pointSize: Style.fontSizeM
                font.weight: Style.fontWeightBold
            }

            NText {
                visible: WeatherService.haveData
                text: (WeatherService.hideLocation ? "" : WeatherService.locationName + "  ") + "H:" + Math.round(WeatherService.highF) + "°  L:" + Math.round(WeatherService.lowF) + "°"
                color: Colors.textMuted
                pointSize: Style.fontSizeS
            }
        }
    }

    // 6-day forecast (bumped from 5 to match Noctalia v5's own reference
    // Control Center, supplied live) - WeatherService.forecastDays[0] is
    // today (same data as the current-conditions line above, just restated
    // as the first cell here for a consistent row rather than a
    // special-cased tail), the rest are the next 5 days.
    Row {
        width: parent.width
        visible: WeatherService.haveData && WeatherService.forecastDays.length > 0

        Repeater {
            model: WeatherService.forecastDays

            Column {
                id: dayCell
                required property var modelData
                width: root.width / 6
                spacing: 2

                NText {
                    text: dayCell.modelData.label
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    color: Colors.textMuted
                    pointSize: Style.fontSizeXS
                    font.weight: Style.fontWeightBold
                }

                NText {
                    text: WeatherService.iconGlyph(dayCell.modelData.weatherCode, true)
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    color: Colors.blue
                    pointSize: Style.fontSizeL
                }

                NText {
                    text: Math.round(dayCell.modelData.highF) + "°/" + Math.round(dayCell.modelData.lowF) + "°"
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    color: Colors.text
                    pointSize: Style.fontSizeXS
                }
            }
        }
    }
}
