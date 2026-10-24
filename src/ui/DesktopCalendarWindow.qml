pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
ApplicationWindow {
    id: calendar
    objectName: "desktopCalendarWindow"
    required property TaskWorkspace workspace
    signal openTask(string taskId)
    width: 760;height: 720
    minimumWidth: 420;minimumHeight: 480
    visible: workspace.ready && workspace.preferences.desktopCalendarVisible
    transientParent: null
    flags: Qt.Window | Qt.FramelessWindowHint | (workspace.preferences.desktopCalendarTopmost ? Qt.WindowStaysOnTopHint : 0)
    title: qsTr("Tilo · 桌面日历")
    color: "transparent"
    font.family: Theme.fontFamily;font.pixelSize: Theme.bodySize
    palette.windowText: Theme.text;palette.text: Theme.text;palette.buttonText: Theme.text
    background: Rectangle {
        objectName: "desktopCalendarBackground"
        Accessible.role: Accessible.Window
        Accessible.name: calendar.title
        color: Qt.rgba(Theme.content.r,Theme.content.g,Theme.content.b,Theme.highContrast ? 1 : calendar.workspace.preferences.desktopCalendarOpacity/100)
        radius: Theme.panelRadius;border.color: Theme.separator
    }
    onClosing: function(event) {
        event.accepted=false
        if(!page.protectClose(function(){calendar.workspace.setPreference("desktopCalendarVisible",false)}))calendar.workspace.setPreference("desktopCalendarVisible",false)
    }
    function protectClose(action) {
        if(!page.protectClose(action))return false
        workspace.setPreference("desktopCalendarVisible",true);requestActivate();return true
    }
    function resetPosition() {x=Screen.virtualX+Math.max(0,(Screen.width-width)/2);y=Screen.virtualY+Math.max(0,(Screen.height-height)/2)}
    // Keyboard entry point: the content root owns the window-level resize/move
    // chords, so it must hold focus when nothing inside the calendar does. It
    // never steals focus from a child control that already has it.
    function focusContent() {if(!activeFocusItem)chrome.forceActiveFocus()}
    // Only react to the window actually being active. forceActiveFocus() on an
    // item of an inactive window requests activation, so doing this on
    // completion would steal focus from the main window at startup.
    onActiveChanged: if(active)focusContent()
    // Keyboard alternative to the resize grip. Ctrl+arrows resize within the
    // same 420x480 floor the mouse path enforces through minimumWidth/Height;
    // Shift+arrows move the window. The window keeps focus so the sequence can
    // be repeated, and the calendar never shrinks past its declared minimum.
    readonly property int keyboardStep: 24
    function keyboardResize(dx,dy) {
        calendar.width=Math.max(calendar.minimumWidth,calendar.width+dx*calendar.keyboardStep)
        calendar.height=Math.max(calendar.minimumHeight,calendar.height+dy*calendar.keyboardStep)
        return true
    }
    function keyboardMove(dx,dy) {
        calendar.x=calendar.x+dx*calendar.keyboardStep
        calendar.y=calendar.y+dy*calendar.keyboardStep
        return true
    }
    // ApplicationWindow is not an Item, so this handler is attached to the
    // content ColumnLayout below and bubbles up from the focused child.
    function handleKey(event) {
        if(!(event.modifiers & Qt.ControlModifier) || event.modifiers & Qt.AltModifier)return false
        const move=event.modifiers & Qt.ShiftModifier
        if(event.key===Qt.Key_Left)move ? calendar.keyboardMove(-1,0) : calendar.keyboardResize(-1,0)
        else if(event.key===Qt.Key_Right)move ? calendar.keyboardMove(1,0) : calendar.keyboardResize(1,0)
        else if(event.key===Qt.Key_Up)move ? calendar.keyboardMove(0,-1) : calendar.keyboardResize(0,-1)
        else if(event.key===Qt.Key_Down)move ? calendar.keyboardMove(0,1) : calendar.keyboardResize(0,1)
        else return false
        event.accepted=true
        return true
    }
    function verifyIndependence() {
        const oldView=workspace.view
        const oldTitle=workspace.calendarTitle
        const original=page.anchorDate
        const originalSelection=page.selectedDate
        page.step(1)
        const changed=page.anchorDate!==original && page.days.length===42
        page.anchorDate=original;page.selectedDate=originalSelection
        return changed && workspace.view===oldView && workspace.calendarTitle===oldTitle
    }
    ColumnLayout {
        id: chrome
        objectName: "desktopCalendarContent"
        anchors.fill: parent;anchors.margins: 14
        spacing: 8
        // The window's resize/move chords need an item to receive keys even
        // when no child control is focused. It must stay out of the Tab chain
        // and must not request focus itself: forceActiveFocus() on a widget of
        // an inactive window would activate this desktop window and pull focus
        // away from the main window while it is still settling.
        Keys.onPressed: function(event){calendar.handleKey(event)}
        RowLayout {
            Layout.fillWidth: true
            Label {text: qsTr("日历");font.weight: Font.DemiBold;Layout.fillWidth: true
                Accessible.role: Accessible.Heading
                DragHandler {target: null;onActiveChanged: if(active)calendar.startSystemMove()}
            }
            WidgetAction {symbol: "pin";description: qsTr("日历置顶");Accessible.checkable: true;Accessible.checked: calendar.workspace.preferences.desktopCalendarTopmost;checked: calendar.workspace.preferences.desktopCalendarTopmost;onClicked: calendar.workspace.setPreference("desktopCalendarTopmost",!checked)}
            WidgetAction {symbol: "settings";description: qsTr("日历透明度与位置");Accessible.description: qsTr("Ctrl+方向键调整大小，Shift+Ctrl+方向键移动");onClicked: options.open()
                Menu {
                        popupType: Popup.Window
                    id: options
                    MenuItem {text: qsTr("背景透明度 %1%").arg(calendar.workspace.preferences.desktopCalendarOpacity);enabled: false}
                    MenuItem {text: qsTr("100% · 实色");onTriggered: calendar.workspace.setPreference("desktopCalendarOpacity",100)}
                    MenuItem {text: "90%";onTriggered: calendar.workspace.setPreference("desktopCalendarOpacity",90)}
                    MenuItem {text: "70%";onTriggered: calendar.workspace.setPreference("desktopCalendarOpacity",70)}
                    MenuItem {text: "50%";onTriggered: calendar.workspace.setPreference("desktopCalendarOpacity",50)}
                    MenuSeparator {}
                    MenuItem {text: qsTr("重置位置");onTriggered: calendar.resetPosition()}
                }
            }
            WidgetAction {symbol: "close";description: qsTr("隐藏桌面日历");onClicked: calendar.close()}
        }
        CalendarPanel {
            id: page
            objectName: "desktopCalendarPanel"
            Layout.fillWidth: true;Layout.fillHeight: true
            workspace: calendar.workspace
            independent: true
            onOpenTask: function(taskId){calendar.openTask(taskId)}
            onCompleteTask: function(taskId,version,action){calendar.workspace.changeState(taskId,version,action)}
        }
        Label {visible: calendar.workspace.errorText.length>0;Layout.fillWidth: true;wrapMode: Text.Wrap;text: calendar.workspace.errorText;color: Theme.danger}
    }
    MouseArea {
        objectName: "desktopCalendarResizeGrip"
        anchors.right: parent.right;anchors.bottom: parent.bottom;width: 16;height: 16
        cursorShape: Qt.SizeFDiagCursor
        onPressed: calendar.startSystemResize(Qt.RightEdge|Qt.BottomEdge)
        Accessible.role: Accessible.Splitter
        Accessible.name: qsTr("调整桌面日历大小")
        Accessible.description: qsTr("Ctrl+方向键调整宽高，Shift+Ctrl+方向键移动")
    }
}
