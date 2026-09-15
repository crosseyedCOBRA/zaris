pragma Singleton
import QtQuick

// Shared open/closed state for the Network flyout (NetworkPanel.qml) -
// same anchorItem-to-the-clicked-icon pattern NotificationHistoryPanel.qml
// already established (centers under whichever specific icon triggered it,
// via BarConfig.popupAnchorY, rather than the bar's own full-width surface
// the way ControlCenterState.qml's barItem does - this opens from one
// small bar icon, not a whole-bar launcher).
// activeTab picks which of the two tabs (Ethernet/Wifi's own reference
// screenshot order, see NetworkPanel.qml) is showing - defaults to
// whichever connection type is actually active when the panel opens
// (the bar module's own click handler sets this before setting visible),
// so it opens already showing whatever's relevant rather than always
// defaulting to one fixed tab regardless of what's connected.
QtObject {
    property bool visible: false
    property Item anchorItem: null
    property string activeTab: "wifi" // "wifi" | "ethernet"
}
