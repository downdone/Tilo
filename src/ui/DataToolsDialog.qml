pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs as NativeDialogs

Dialog {
    id: root
    background: Rectangle {color: Theme.sidebar;radius: 16;border.color: Theme.separator}
    required property TaskWorkspace workspace
    property bool restorePrepared: false
    width: Math.min(550,parent.width-40)
    height: Math.min(600,parent.height-32)
    title: qsTr("数据导出、导入与恢复")
    modal: true
    closePolicy: Popup.NoAutoClose
    onVisibleChanged: if(!visible)restorePrepared=false
    Connections {target: root.workspace
        function onOperationFinished(operation,success){
            if(operation==="applyImport" && success)root.restorePrepared=false
        }}
    Shortcut {sequence: "Escape";enabled: root.visible && !root.workspace.busy && !replaceFirst.visible && !replaceSecond.visible;onActivated: root.close()}
    contentItem: ScrollView {
        clip: true
    ColumnLayout {
        width: root.availableWidth-12
        spacing: Theme.fieldGap
        enabled: !root.workspace.busy
        Label { text: qsTr("数据只保存在本机。JSON保留任务、事件、关联、组织、清单和重复规则；CSV仅导出任务供表格阅读。"); Layout.fillWidth: true; wrapMode: Text.Wrap }
        FormGroup {
            heading: qsTr("导出与备份")
            detail: qsTr("JSON保留全部内容，CSV供表格阅读；快照用于完整恢复。")
        Flow {
            Layout.fillWidth: true;spacing: Theme.gap
            ActionButton {symbol: "export"; text: qsTr("导出JSON…"); onClicked: exportJson.open() }
            ActionButton {symbol: "export"; text: qsTr("导出CSV…"); onClicked: exportCsv.open() }
            ActionButton {symbol: "backup"; text: qsTr("创建快照"); onClicked: root.workspace.createBackup() }
        }
        }
        FormGroup {
            heading: qsTr("导入与恢复")
            detail: qsTr("先预览，再选择仅添加或替换。")
        Flow {
            Layout.fillWidth: true;spacing: Theme.gap
            ActionButton {symbol: "import"; text: qsTr("预览JSON导入…"); onClicked: importJson.open() }
            ActionButton {symbol: "backup"; text: qsTr("从快照恢复…"); enabled: true; onClicked: restoreSnapshot.open() }
        }
        Label { text: root.workspace.importSummary; visible: text.length>0; Layout.fillWidth: true; wrapMode: Text.Wrap }
        Flow {
            Layout.fillWidth: true;spacing: Theme.gap
            visible: root.workspace.importSummary.length>0 && !root.restorePrepared
            Button { highlighted: true;text: qsTr("仅添加，跳过相同ID"); onClicked: root.workspace.applyImport(false) }
            Button { text: qsTr("替换当前数据…"); palette.buttonText: Theme.danger; flat: true; onClicked: replaceFirst.open() }
        }
        Button {
            // Restoring a snapshot always replaces; "adding" a backup silently
            // merges two datasets, so that path is not offered for snapshots.
            objectName: "confirmRestoreSnapshot"
            visible: root.restorePrepared
            Layout.fillWidth: true
            highlighted: true
            text: qsTr("恢复此快照并替换全部数据…")
            onClicked: restoreFirst.open()
        }
        Label { visible: root.restorePrepared; Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: Theme.captionSize; color: Theme.secondary
                text: qsTr("恢复会先用当前数据创建快照，再整体替换；无法合并到现有数据。") }
        Label { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: Theme.captionSize; color: Theme.secondary
                text: qsTr("数据文件夹：%1").arg(root.workspace.dataDirectory()) }
        }
        Label { text: root.workspace.errorText || root.workspace.infoText; Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.workspace.errorText ? Theme.danger : Theme.success }
        Label { text: qsTr("默认每日首次启动自动保留快照（最近7份）。替换/恢复前另建完整快照；损坏导入不修改数据。"); Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: Theme.captionSize; color: Theme.secondary }
    }
    }
    footer: DialogButtonBox { Button { text: qsTr("返回"); enabled: !root.workspace.busy; onClicked: root.close() } }
    NativeDialogs.FileDialog { id: exportJson; title: qsTr("导出Tilo JSON"); fileMode: NativeDialogs.FileDialog.SaveFile; nameFilters: ["Tilo JSON (*.json)"]; defaultSuffix: "json"; onAccepted: root.workspace.exportData(selectedFile.toString(),false) }
    NativeDialogs.FileDialog { id: exportCsv; title: qsTr("导出CSV"); fileMode: NativeDialogs.FileDialog.SaveFile; nameFilters: ["CSV (*.csv)"]; defaultSuffix: "csv"; onAccepted: root.workspace.exportData(selectedFile.toString(),true) }
    NativeDialogs.FileDialog { id: importJson; title: qsTr("选择Tilo JSON"); fileMode: NativeDialogs.FileDialog.OpenFile; nameFilters: ["Tilo JSON (*.json)"]; onAccepted: root.workspace.previewImport(selectedFile.toString(),false) }
    NativeDialogs.FileDialog { id: restoreSnapshot; title: qsTr("选择Tilo一致性快照"); fileMode: NativeDialogs.FileDialog.OpenFile; nameFilters: ["Tilo snapshot (*.sqlite)"]; onAccepted: {root.restorePrepared=true;root.workspace.previewImport(selectedFile.toString(),true)} }
    Dialog {
        id: replaceFirst
        parent: Overlay.overlay
        width: Math.min(440,root.parent.width-40)
        height: Math.min(180*Theme.scale,root.parent.height-40)
        modal: true
        title: qsTr("替换会移除当前全部数据")
        contentItem: Label { text: qsTr("当前数据会被预览文件替代。先创建备份，再事务替换。继续？");wrapMode: Text.Wrap }
        footer: ActionBar {
            Button {objectName: "cancelReplaceFirst";text: qsTr("不替换");onClicked: replaceFirst.reject()}
            Button {objectName: "confirmReplaceFirst";text: qsTr("继续");palette.buttonText: Theme.danger;onClicked: replaceFirst.accept()}
        }
        onAccepted: replaceSecond.open()
    }
    Dialog {
        id: restoreFirst
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(440,root.parent.width-40)
        modal: true
        title: qsTr("恢复会替换当前全部数据")
        contentItem: Label { text: qsTr("将先为当前数据创建快照，再用所选备份整体替换。继续？");wrapMode: Text.Wrap }
        footer: ActionBar {
            Button {objectName: "cancelRestoreFirst";text: qsTr("不恢复");onClicked: restoreFirst.reject()}
            Button {objectName: "confirmRestoreFirst";text: qsTr("继续");palette.buttonText: Theme.danger;onClicked: restoreFirst.accept()}
        }
        onAccepted: restoreSecond.open()
    }
    Dialog {
        id: restoreSecond
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(440,root.parent.width-40)
        modal: true
        title: qsTr("最后确认恢复")
        contentItem: Label { text: qsTr("确认用已验证的备份替换本机数据？备份失败则不执行。");wrapMode: Text.Wrap }
        footer: ActionBar {
            Button {objectName: "cancelRestoreSecond";text: qsTr("不恢复");onClicked: restoreSecond.reject()}
            Button {objectName: "confirmRestoreSecond";text: qsTr("确认恢复");palette.buttonText: Theme.danger;onClicked: restoreSecond.accept()}
        }
        onAccepted: root.workspace.restoreFromFile(restoreSnapshot.selectedFile.toString(),true)
    }
    Dialog {
        id: replaceSecond
        parent: Overlay.overlay
        width: Math.min(440,root.parent.width-40)
        height: Math.min(180*Theme.scale,root.parent.height-40)
        modal: true
        title: qsTr("最后确认替换")
        contentItem: Label { text: qsTr("确认使用已验证的预览替换本机数据？备份失败则不执行。");wrapMode: Text.Wrap }
        footer: ActionBar {
            Button {objectName: "cancelReplaceSecond";text: qsTr("不替换");onClicked: replaceSecond.reject()}
            Button {objectName: "confirmReplaceSecond";text: qsTr("确认替换");palette.buttonText: Theme.danger;onClicked: replaceSecond.accept()}
        }
        onAccepted: root.workspace.applyImport(true)
    }
}
