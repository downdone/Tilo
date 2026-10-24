pragma ComponentBehavior: Bound
import QtQuick
import TiloStyle as DS
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: widget
    required property WidgetViewModel controller
    required property TaskWorkspace workspace
    signal newTaskRequested()
    signal openMainRequested()
    // Enter on a widget row raises the main window with that row selected. The
    // widget never opens its own editor: the main window owns the single one.
    signal openTaskRequested(string taskId)
    signal settingsRequested()
    objectName: "widgetWindow"
    width: 340
    height: 360
    minimumWidth: 260
    minimumHeight: widget.controller.mini ? 48 : 190
    x: 80
    y: 80
    visible: false
    color: "transparent"
    title: qsTr("Tilo 今日任务")
    // The list takes keyboard focus only once this window is genuinely active.
    // Setting focus:true while the widget sits behind an inactive window would
    // make the widget request activation and fight the main window.
    onActiveChanged: if(active && !todayList.activeFocus) todayList.forceActiveFocus()
    function verifyMenu() {
        if(!widgetMenu.visible)return "closed"
        for(let i=0;i<widgetMenu.count;i++) {
            const item=widgetMenu.itemAt(i) as MenuItem
            if(item && item.text && item.width<item.implicitWidth-1)return "clipped item "+i+": "+item.width+"/"+item.implicitWidth
        }
        return "PASS"
    }
    function openVerificationMenu() {widgetMenu.open()}
    function closeVerificationMenu() {widgetMenu.close()}
    // Keyboard alternative to the corner grip: Ctrl+arrows resize within the
    // same 260x190 floor as the pointer path, Shift+Ctrl+arrows move the
    // floating window. Both are ignored while locked or mini.
    readonly property int keyboardStep: 16
    function keyboardResize(dx,dy) {
        if(widget.controller.locked || widget.controller.mini)return false
        widget.width=Math.max(widget.minimumWidth,widget.width+dx*widget.keyboardStep)
        widget.height=Math.max(widget.minimumHeight,widget.height+dy*widget.keyboardStep)
        return true
    }
    function keyboardMove(dx,dy) {
        if(widget.controller.locked || widget.controller.mini)return false
        widget.x=widget.x+dx*widget.keyboardStep
        widget.y=widget.y+dy*widget.keyboardStep
        return true
    }
    function handleKey(event) {
        if(!(event.modifiers & Qt.ControlModifier) || event.modifiers & Qt.AltModifier)return false
        const move=event.modifiers & Qt.ShiftModifier
        if(event.key===Qt.Key_Left)move ? widget.keyboardMove(-1,0) : widget.keyboardResize(-1,0)
        else if(event.key===Qt.Key_Right)move ? widget.keyboardMove(1,0) : widget.keyboardResize(1,0)
        else if(event.key===Qt.Key_Up)move ? widget.keyboardMove(0,-1) : widget.keyboardResize(0,-1)
        else if(event.key===Qt.Key_Down)move ? widget.keyboardMove(0,1) : widget.keyboardResize(0,1)
        else return false
        event.accepted=true
        return true
    }

    Control {
        anchors.fill: parent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.bodySize
        palette.window: Theme.content
        palette.windowText: Theme.text
        palette.text: Theme.text
        palette.button: Theme.sidebar
        palette.buttonText: Theme.text
        palette.highlight: Theme.accent
        // Window is not an Item, so the resize/move keys live on the content
        // control and bubble up from whichever row currently has focus.
        Keys.onPressed: function(event){widget.handleKey(event)}
        contentItem: Rectangle {
        radius: Theme.panelRadius
        color: Qt.rgba(Theme.content.r, Theme.content.g, Theme.content.b, widget.workspace.preferences.solidWidget || Theme.highContrast ? 1 : widget.controller.backgroundOpacity)
        border.color: Theme.separator

        ColumnLayout {
            visible: !widget.controller.mini
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8
            RowLayout {
                objectName: "widgetHeader"
                Layout.fillWidth: true
                spacing: 2
                Item {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.preferredHeight: Math.max(32,headerText.implicitHeight)
                    Column {
                        id: headerText
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        Label {width: parent.width;text: qsTr("今天");font.bold: true;color: Theme.text;elide: Text.ElideRight;Accessible.role: Accessible.Heading}
                        Label {width: parent.width;text: qsTr("待办 %1 · 完成 %2").arg(widget.workspace.todayTasks.count).arg(widget.workspace.completedToday);font.pixelSize: Theme.captionSize;color: Theme.secondary;elide: Text.ElideRight;Accessible.role: Accessible.StaticText}
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeAllCursor
                        onPressed: widget.controller.startMove()
                    }
                }
                WidgetAction {objectName: "widgetAdd";symbol: "plus";description: qsTr("添加今日任务");onClicked: widget.newTaskRequested()}
                WidgetAction {
                    objectName: "widgetPin"
                    symbol: "pin"
                    checked: widget.controller.alwaysOnTop
                    Accessible.checkable: true
                    Accessible.checked: checked
                    description: checked ? qsTr("取消置顶") : qsTr("置顶组件")
                    onClicked: widget.controller.setAlwaysOnTop(!widget.controller.alwaysOnTop)
                }
                WidgetAction {objectName: "widgetCollapse";symbol: "collapse";description: qsTr("收起为迷你条");onClicked: widget.controller.setMini(true)}
                WidgetAction {
                    objectName: "widgetMore"
                    description: qsTr("组件菜单")
                    onClicked: widgetMenu.open()
                    Menu {
                        popupType: Popup.Window
                        id: widgetMenu
                        objectName: "widgetMenu"
                        x: parent.width-width
                        y: parent.height
                        MenuItem {text: qsTr("打开主窗口");onTriggered: widget.openMainRequested()}
                        MenuSeparator {}
                        MenuItem {text: qsTr("保持置顶");checkable: true;checked: widget.controller.alwaysOnTop;onTriggered: widget.controller.setAlwaysOnTop(checked)}
                        MenuItem {text: qsTr("锁定拖动");checkable: true;checked: widget.controller.locked;onTriggered: widget.controller.setLocked(checked)}
                        MenuItem {text: qsTr("鼠标穿透（托盘/主窗恢复）");enabled: widget.controller.trayAvailable;onTriggered: widget.controller.setClickThrough(true)}
                        MenuItem {text: qsTr("外观与组件设置…");onTriggered: widget.settingsRequested()}
                        MenuSeparator {}
                        MenuItem {text: qsTr("隐藏组件");onTriggered: widget.controller.setVisible(false)}
                    }
                }
            }
            Rectangle {Layout.fillWidth: true;implicitHeight: 1;color: Theme.separator}
            Label {
                Layout.fillWidth: true
                visible: widget.workspace.todayTasks.count === 0
                text: widget.workspace.ready ? qsTr("今天暂无任务\n在主窗口的“今天”页面添加任务。") : qsTr("正在加载本地任务…")
                color: Theme.secondary
                lineHeight: 1.4
                Accessible.role: Accessible.StaticText
                Accessible.name: text
            }
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                visible: widget.controller.errorText.length > 0 || widget.workspace.errorText.length > 0
                text: widget.workspace.errorText || widget.controller.errorText
                font.pixelSize: Theme.captionSize
                color: Theme.danger
                Accessible.role: Accessible.AlertMessage
                Accessible.name: text
            }
            ListView {
                // Avoid background row incubation across model resets on Qt 6.10.2.
                cacheBuffer: 0
                DS.ScrollPhysics {target: todayList;keyboardNavigationEnabled: true}
                id: todayList
                objectName: "widgetTasks"
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                model: widget.workspace.todayTasks
                activeFocusOnTab: true
                keyNavigationWraps: true
                Accessible.role: Accessible.List
                Accessible.name: qsTr("今天待办 %1 项").arg(widget.workspace.todayTasks.count)
                Accessible.description: qsTr("上下键浏览，Enter 打开任务详情，空格完成")
                ScrollBar.vertical: ScrollBar {}
                function activateRow(row) {row.openTask()}
                function completeRow(row) {row.completeTask()}
                // Ctrl+arrows belong to the window (resize/move), so the list
                // must not consume them as navigation. Unmodified arrows keep
                // their normal list behaviour by staying unaccepted here.
                Keys.onUpPressed: function(event){if(widget.handleKey(event))return;event.accepted=false}
                Keys.onDownPressed: function(event){if(widget.handleKey(event))return;event.accepted=false}
                Keys.onLeftPressed: function(event){if(widget.handleKey(event))return;event.accepted=false}
                Keys.onRightPressed: function(event){if(widget.handleKey(event))return;event.accepted=false}
                Keys.onReturnPressed: function(event){event.accepted=true;const row=todayList.currentItem;if(row)todayList.activateRow(row)}
                Keys.onEnterPressed: function(event){event.accepted=true;const row=todayList.currentItem;if(row)todayList.activateRow(row)}
                Keys.onSpacePressed: function(event){event.accepted=true;const row=todayList.currentItem;if(row)todayList.completeRow(row)}
                delegate: ItemDelegate {
                    required property string taskId
                    required property string title
                    required property real rowVersion
                    required property int index
                    id: todayRow
                    width: todayList.width
                    readonly property bool current: ListView.isCurrentItem && todayList.activeFocus
                    // The widget never opens a second editor of its own: Enter
                    // raises the main window, which owns the single editor.
                    function openTask() {widget.openTaskRequested(taskId)}
                    function completeTask() {if(widget.workspace.ready && !widget.workspace.busy)widget.workspace.changeState(taskId, rowVersion, "complete")}
                    Accessible.role: Accessible.ListItem
                    Accessible.name: title
                    Accessible.description: qsTr("Enter 打开，空格完成")
                    // The row is the focus item, and an ItemDelegate's button base
                    // would otherwise swallow Space/Enter as its own activation.
                    // Handling them first keeps Space=complete, Enter=open.
                    Keys.priority: Keys.BeforeItem
                    Keys.onSpacePressed: function(event){event.accepted=true;todayRow.completeTask()}
                    Keys.onReturnPressed: function(event){event.accepted=true;todayRow.openTask()}
                    Keys.onEnterPressed: function(event){event.accepted=true;todayRow.openTask()}
                    padding: 2
                    onClicked: todayRow.current ? todayRow.completeTask() : todayList.currentIndex=index
                    contentItem: RowLayout {
                        IconToolButton {
                            Layout.preferredWidth: Math.max(32,Theme.iconSize+12)
                            Layout.preferredHeight: Math.max(32,Theme.iconSize+12)
                            contentItem: Item {
                                implicitWidth: Theme.iconSize;implicitHeight: Theme.iconSize
                                AppIcon {anchors.centerIn: parent;width: Theme.iconSize;height: width;name: "circle"}
                            }
                            Accessible.role: Accessible.Button
                            Accessible.name: qsTr("完成任务：%1").arg(todayRow.title)
                            enabled: widget.workspace.ready && !widget.workspace.busy
                            onClicked: todayRow.completeTask()
                        }
                        Label { Layout.fillWidth: true; text: todayRow.title; elide: Text.ElideRight; color: Theme.text }
                    }
                    background: Rectangle {
                        radius: 6
                        color: "transparent"
                        // Non-colour focus cue: a 2px ring and a leading accent bar.
                        border.width: todayRow.current ? 2 : 0
                        border.color: Theme.accent
                        Rectangle {x: 1;y: 4;width: 3;height: parent.height-8;radius: 1.5;color: Theme.accent;visible: todayRow.current}
                    }
                }
            }
        }

        RowLayout {
            visible: widget.controller.mini
            anchors.fill: parent
            anchors.margins: 6
            spacing: 6
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Label {
                    anchors.centerIn: parent
                    width: parent.width
                    elide: Text.ElideRight
                    text: qsTr("今日 %1 项").arg(widget.workspace.todayTasks.count)+(widget.workspace.todayTasks.count>0 ? " · "+widget.workspace.firstTodayTitle : "")
                    font.pixelSize: Theme.captionSize
                    color: Theme.text
                    Accessible.role: Accessible.StaticText
                    Accessible.name: text
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.SizeAllCursor
                    onPressed: widget.controller.startMove()
                }
            }
            WidgetAction {objectName: "widgetExpand";symbol: "expand";description: qsTr("展开任务组件");onClicked: widget.controller.setMini(false)}
        }
        MouseArea {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 16
            height: 16
            visible: !widget.controller.mini && !widget.controller.locked
            cursorShape: Qt.SizeFDiagCursor
            onPressed: widget.controller.startResize()
            Accessible.role: Accessible.Splitter
            Accessible.name: qsTr("调整组件大小")
            Accessible.description: qsTr("Ctrl+方向键调整宽高，Shift+Ctrl+方向键移动")
        }
        }
    }
}
