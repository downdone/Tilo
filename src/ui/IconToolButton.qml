import QtQuick
import QtQuick.Controls
ToolButton {
    id: control
    // Icon-only actions still need a visible, non-colour keyboard cue; the
    // control background may be overridden by callers, so draw the ring here.
    // Uses `visualFocus` so pointer clicks do not leave a stray focus rect.
    readonly property bool keyboardFocus: visualFocus
    ToolTip.visible: enabled && (hovered || activeFocus) && Accessible.name.length>0
    ToolTip.delay: 600
    ToolTip.text: Accessible.name
    Rectangle {
        objectName: "iconFocusRing"
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.min(width,height)/2
        color: "transparent"
        border.width: control.keyboardFocus ? 2 : 0
        border.color: Theme.accent
        visible: control.keyboardFocus
    }
}
