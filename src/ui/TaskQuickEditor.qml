pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
Control {
    id: root
    objectName: "taskQuickEditor"
    required property TaskWorkspace workspace
    property bool dirty: false
    property bool guardActive: false
    property string titleText: ""
    property string notesText: ""
    property string startOn: ""
    property string deadlineOn: ""
    property string reminderText: ""
    property var destinations: []
    property var tags: []
    property var tagIds: []
    property string destinationId: ""
    readonly property bool multilineNotes: notesText.indexOf("\n")>=0
    readonly property var hostWindow: Window.window
    readonly property bool pickerVisible: quickStart.pickerVisible || quickEnd.pickerVisible || reminder.pickerVisible || tagPicker.visible || destinationPicker.visible
    signal titleEdited(string value)
    signal notesEdited(string value)
    signal startEdited(string value)
    signal deadlineEdited(string value)
    signal reminderEdited(string value)
    signal destinationEdited(string kind,string id)
    signal tagEdited(string id,bool checked)
    signal createCatalogRequested(string kind)
    signal detailsRequested()
    signal closeRequested()
    signal saveRequested()
    signal completeRequested()
    signal focusRequested(Item item)
    property bool editing: false
    visible: editing
    padding: 10
    implicitHeight: implicitContentHeight+topPadding+bottomPadding
    function open(){editing=true;Qt.callLater(focusTitle)}
    function close(){quickStart.closePicker();quickEnd.closePicker();reminder.closePicker();tagPicker.close();destinationPicker.close();editing=false}
    function focusTitle(){quickTitle.forceActiveFocus();focusRequested(quickTitle)}
    // One row of title actions plus a note summary and an icon row must stay
    // compact at every text scale. Each term reports its measurement so a
    // failure names the budget that broke instead of a generic message.
    function verifyLayout(){
        const budget=170*Theme.scale
        if(width<=0)return "card has no width"
        if(height>budget)return "card height "+Math.round(height)+" > "+Math.round(budget)
        if(quickTitle.font.pixelSize!==Theme.bodySize)return "title typography "+quickTitle.font.pixelSize+" vs "+Theme.bodySize
        if(quickNotes.font.pixelSize!==Theme.captionSize)return "note typography "+quickNotes.font.pixelSize+" vs "+Theme.captionSize
        return "PASS"
    }
    Shortcut {sequence: "Escape";enabled: root.visible && !root.guardActive && !root.pickerVisible;onActivated: root.closeRequested()}
    Shortcut {sequence: Qt.platform.os==="osx" ? "Meta+Return" : "Ctrl+Return";enabled: root.visible && !root.guardActive && !root.pickerVisible;onActivated: root.saveRequested()}
    contentItem: ColumnLayout {
        spacing: 2
        enabled: !root.workspace.busy || root.workspace.backgroundBusy
        // Tab chain for the card: the Scheduling controls sit between the note
        // summary and the trailing title actions so a keyboard user can reach
        // every icon and leave the card again with Tab/Shift+Tab.
        RowLayout {
            Layout.fillWidth: true;spacing: 8
            IconToolButton {id: inlineCompleteTask;objectName: "inlineCompleteTask";KeyNavigation.tab: quickTitle;Accessible.name: qsTr("完成任务：%1").arg(root.titleText);contentItem: Item {implicitWidth: Theme.iconSize;implicitHeight: Theme.iconSize;Rectangle {anchors.centerIn: parent;width: Theme.iconSize;height: width;radius: width/2;color: "transparent";border.color: Theme.secondary;border.width: 1.5}} onClicked: root.completeRequested()}
            TextField {
                id: quickTitle;objectName: "quickEditorTitle"
                Layout.fillWidth: true
                font.pixelSize: Theme.bodySize;font.weight: Font.Normal
                leftPadding: 0;rightPadding: 0;background: Item {}
                KeyNavigation.tab: quickNotes;KeyNavigation.backtab: inlineCompleteTask
                Accessible.name: qsTr("任务标题")
                onTextEdited: root.titleEdited(text)
                onAccepted: root.saveRequested()
                onActiveFocusChanged: if(activeFocus)root.focusRequested(quickTitle)
            }
            Binding {target: quickTitle;property: "text";value: root.titleText}
            IconToolButton {id: detailsButton;objectName: "quickEditorDetails";KeyNavigation.tab: saveButton;KeyNavigation.backtab: reminder;contentItem: AppIcon {name: "info"} Accessible.name: qsTr("完整任务详情");onClicked: root.detailsRequested()}
            IconToolButton {id: saveButton;objectName: "saveQuickEditor";KeyNavigation.backtab: detailsButton;contentItem: AppIcon {name: root.dirty ? "check" : "up";ink: root.dirty ? Theme.accent : Theme.secondary} Accessible.name: root.dirty ? qsTr("保存并收起，Ctrl+Enter") : qsTr("收起任务，Esc");onClicked: root.dirty ? root.saveRequested() : root.closeRequested()}
        }
        TextField {
            id: quickNotes;objectName: "quickEditorNotes"
            Layout.fillWidth: true;Layout.leftMargin: 40
            font.pixelSize: Theme.captionSize;color: Theme.secondary
            implicitHeight: Math.max(24,contentHeight+4)
            padding: 2;leftPadding: 0;readOnly: root.multilineNotes
            KeyNavigation.tab: quickStart;KeyNavigation.backtab: quickTitle
            placeholderText: qsTr("添加备注…")
            Accessible.name: root.multilineNotes ? qsTr("多行备注摘要，点击在详情编辑") : qsTr("一行备注")
            background: Item {}
            onTextEdited: root.notesEdited(text)
            onAccepted: root.saveRequested()
            onActiveFocusChanged: if(activeFocus)root.focusRequested(quickNotes)
            TapHandler {enabled: root.multilineNotes;onTapped: root.detailsRequested()}
        }
        Binding {target: quickNotes;property: "text";value: root.multilineNotes ? root.notesText.split("\n")[0]+"…" : root.notesText}
        Flow {
            Layout.fillWidth: true;Layout.leftMargin: 40;spacing: 6
            DateField {
                id: quickStart;objectName: "quickEditorStart"
                workspace: root.workspace;iconOnly: true;dateLabel: qsTr("计划开始：%1").arg(text || qsTr("未设置"))
                width: Math.max(36,Theme.iconSize+16);height: width;implicitWidth: width
                readOnly: true;activeFocusOnTab: true;color: "transparent";leftPadding: 0;placeholderText: ""
                KeyNavigation.tab: quickEnd;KeyNavigation.backtab: quickNotes
                Accessible.role: Accessible.EditableText
                Accessible.description: qsTr("按 Enter 或空格选择日期，Alt+下箭头打开日历")
                background: Rectangle {radius: height/2;border.width: quickStart.activeFocus ? 2 : 0;border.color: Theme.accent;color: quickStart.text ? Theme.selected : Theme.sidebar}
                onDateChosen: root.startEdited(text)
                onActiveFocusChanged: if(activeFocus)root.focusRequested(quickStart)
                // Plain Enter/Space only: Ctrl+Enter stays the card's save
                // shortcut and must reach it rather than the picker.
                Keys.onReturnPressed: function(event){if(event.modifiers & Qt.ControlModifier){event.accepted=false;return}event.accepted=true;if(quickStart.pickerVisible)quickStart.closePicker();else quickStart.openPicker()}
                Keys.onEnterPressed: function(event){if(event.modifiers & Qt.ControlModifier){event.accepted=false;return}event.accepted=true;if(quickStart.pickerVisible)quickStart.closePicker();else quickStart.openPicker()}
                Keys.onSpacePressed: function(event){event.accepted=true;if(quickStart.pickerVisible)quickStart.closePicker();else quickStart.openPicker()}
                Keys.onEscapePressed: function(event){event.accepted=true;if(quickStart.pickerVisible)quickStart.closePicker();else root.closeRequested()}
            }
            Binding {target: quickStart;property: "text";value: root.startOn}
            DateField {
                id: quickEnd;objectName: "quickEditorDeadline"
                workspace: root.workspace;iconOnly: true;dateLabel: qsTr("截止日期：%1").arg(text || qsTr("未设置"));symbol: "flag"
                width: Math.max(36,Theme.iconSize+16);height: width;implicitWidth: width
                readOnly: true;activeFocusOnTab: true;color: "transparent";leftPadding: 0;placeholderText: ""
                KeyNavigation.tab: tagButton;KeyNavigation.backtab: quickStart
                Accessible.role: Accessible.EditableText
                Accessible.description: qsTr("按 Enter 或空格选择日期，Alt+下箭头打开日历")
                background: Rectangle {radius: height/2;border.width: quickEnd.activeFocus ? 2 : 0;border.color: Theme.accent;color: quickEnd.text ? Theme.selected : Theme.sidebar}
                onDateChosen: root.deadlineEdited(text)
                onActiveFocusChanged: if(activeFocus)root.focusRequested(quickEnd)
                Keys.onReturnPressed: function(event){if(event.modifiers & Qt.ControlModifier){event.accepted=false;return}event.accepted=true;if(quickEnd.pickerVisible)quickEnd.closePicker();else quickEnd.openPicker()}
                Keys.onEnterPressed: function(event){if(event.modifiers & Qt.ControlModifier){event.accepted=false;return}event.accepted=true;if(quickEnd.pickerVisible)quickEnd.closePicker();else quickEnd.openPicker()}
                Keys.onSpacePressed: function(event){event.accepted=true;if(quickEnd.pickerVisible)quickEnd.closePicker();else quickEnd.openPicker()}
                Keys.onEscapePressed: function(event){event.accepted=true;if(quickEnd.pickerVisible)quickEnd.closePicker();else root.closeRequested()}
            }
            Binding {target: quickEnd;property: "text";value: root.deadlineOn}
            IconToolButton {
                id: tagButton
                width: quickStart.width;height: width
                KeyNavigation.tab: destinationButton;KeyNavigation.backtab: quickEnd
                background: Rectangle {radius: height/2;color: tagButton.down ? Theme.pressed : tagButton.hovered ? Theme.hover : root.tagIds.length>0 ? Theme.selected : Theme.sidebar}
                contentItem: AppIcon {name: "tag";ink: root.tagIds.length>0 ? Theme.accent : Theme.secondary}
                Accessible.name: qsTr("选择标签，已选%1个").arg(root.tagIds.length)
                onClicked: tagPicker.open()
                Keys.onReturnPressed: function(event){event.accepted=true;tagPicker.visible ? tagPicker.close() : tagPicker.open()}
                Keys.onEnterPressed: function(event){event.accepted=true;tagPicker.visible ? tagPicker.close() : tagPicker.open()}
                Keys.onSpacePressed: function(event){event.accepted=true;tagPicker.visible ? tagPicker.close() : tagPicker.open()}
                Keys.onEscapePressed: function(event){event.accepted=true;if(tagPicker.visible)tagPicker.close();else root.closeRequested()}
                CatalogPicker {id: tagPicker;heading: qsTr("标签");options: root.tags;multiple: true;selectedIds: root.tagIds;heightLimit: root.hostWindow ? root.hostWindow.height-32 : 440;y: tagButton.height+4;onSelected: function(kind,id,checked){root.tagEdited(id,checked)};onCreateRequested: function(kind){root.createCatalogRequested(kind)}}
            }
            IconToolButton {
                id: destinationButton
                width: quickStart.width;height: width
                KeyNavigation.tab: reminder;KeyNavigation.backtab: tagButton
                background: Rectangle {radius: height/2;color: destinationButton.down ? Theme.pressed : destinationButton.hovered ? Theme.hover : root.destinationId ? Theme.selected : Theme.sidebar}
                contentItem: AppIcon {name: "project";ink: root.destinationId ? Theme.accent : Theme.secondary}
                Accessible.name: qsTr("选择项目或领域")
                onClicked: destinationPicker.open()
                Keys.onReturnPressed: function(event){event.accepted=true;destinationPicker.visible ? destinationPicker.close() : destinationPicker.open()}
                Keys.onEnterPressed: function(event){event.accepted=true;destinationPicker.visible ? destinationPicker.close() : destinationPicker.open()}
                Keys.onSpacePressed: function(event){event.accepted=true;destinationPicker.visible ? destinationPicker.close() : destinationPicker.open()}
                Keys.onEscapePressed: function(event){event.accepted=true;if(destinationPicker.visible)destinationPicker.close();else root.closeRequested()}
                CatalogPicker {id: destinationPicker;heading: qsTr("放入项目或领域");options: root.destinations;selectedIds: [root.destinationId];heightLimit: root.hostWindow ? root.hostWindow.height-32 : 440;y: destinationButton.height+4;onSelected: function(kind,id,checked){root.destinationEdited(kind,id)};onCreateRequested: function(kind){root.createCatalogRequested(kind)}}
            }
            ReminderField {
                id: reminder;objectName: "quickEditorReminder";workspace: root.workspace;iconOnly: true;commitTask: true
                width: Math.max(36,Theme.iconSize+16);height: width;implicitWidth: width
                readOnly: true;activeFocusOnTab: true;color: "transparent";leftPadding: 0;placeholderText: ""
                KeyNavigation.tab: detailsButton;KeyNavigation.backtab: destinationButton
                Accessible.role: Accessible.EditableText
                Accessible.description: qsTr("按 Enter 或空格选择提醒时间")
                background: Rectangle {radius: height/2;border.width: reminder.activeFocus ? 2 : 0;border.color: Theme.accent;color: reminder.text ? Theme.selected : Theme.sidebar}
                onReminderChosen: root.reminderEdited(text)
                onActiveFocusChanged: if(activeFocus)root.focusRequested(reminder)
                Keys.onReturnPressed: function(event){if(event.modifiers & Qt.ControlModifier){event.accepted=false;return}event.accepted=true;if(reminder.pickerVisible)reminder.closePicker();else reminder.openPicker()}
                Keys.onEnterPressed: function(event){if(event.modifiers & Qt.ControlModifier){event.accepted=false;return}event.accepted=true;if(reminder.pickerVisible)reminder.closePicker();else reminder.openPicker()}
                Keys.onSpacePressed: function(event){event.accepted=true;if(reminder.pickerVisible)reminder.closePicker();else reminder.openPicker()}
                Keys.onEscapePressed: function(event){event.accepted=true;if(reminder.pickerVisible)reminder.closePicker();else root.closeRequested()}
            }
            Binding {target: reminder;property: "text";value: root.reminderText}
            Label {text: [root.startOn ? qsTr("开始 %1").arg(root.startOn.slice(5)) : "",root.deadlineOn ? qsTr("截止 %1").arg(root.deadlineOn.slice(5)) : ""].filter(item=>item.length>0).join(" · ");visible: text.length>0;topPadding: 8;color: Theme.secondary;font.pixelSize: Theme.captionSize}
        }
        Label {Layout.fillWidth: true;Layout.leftMargin: 40;visible: text.length>0;text: root.workspace.errorText;color: Theme.danger;wrapMode: Text.Wrap;font.pixelSize: Theme.captionSize}
    }
}
