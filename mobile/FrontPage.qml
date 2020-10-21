import QtQuick 2.0
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.4
import QtQuick.Dialogs 1.2 as Dialogs

import lith 1.0

ColumnLayout {
    SystemPalette {
        id: palette
    }

    Frame {
        Layout.fillWidth: true
        background: Rectangle {
            color: palette.window
        }

        RowLayout {
            width: parent.width
            Button {
                Layout.preferredWidth: height
                font.pointSize: 20
                text: "☰"
                onClicked: bufferDrawer.visible = !bufferDrawer.visible
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0
                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    height: 1
                    font.bold: true
                    font.family: "Menlo"
                    font.pointSize: stuff.selected && stuff.selected.title.length > 0 ? 14 : 18
                    color: palette.windowText
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: stuff.selected ? stuff.selected.name : ""
                }
                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: stuff.selected && stuff.selected.title.length > 0
                    clip: true
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    text: stuff.selected ? stuff.selected.title : ""
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    font.family: "Menlo"
                    font.pointSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: palette.windowText
                }
            }
            Item { width: 1 }
            Button {
                Layout.preferredWidth: height
                font.pointSize: 20
                visible: weechat.status !== Weechat.UNCONFIGURED
                enabled: weechat.status === Weechat.CONNECTED
                text: weechat.status === Weechat.CONNECTING ? "🤔" :
                      weechat.status === Weechat.CONNECTED ? "🙂" :
                      weechat.status === Weechat.DISCONNECTED ? "😴" :
                      weechat.status === Weechat.ERROR ? "☠" :
                                                         "😱"
                onClicked: nickDrawer.visible = !nickDrawer.visible
            }
        }
    }
    Text {
        Layout.fillHeight: true
        Layout.fillWidth: true
        visible: !stuff.selected
        text: "Welcome to Lith\n" +
              "Weechat status: " + weechat.status + "\n" +
              "Current error status: " + (weechat.errorString.length > 0 ? weechat.errorString : "None")
        color: palette.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        MessageList {
            width: parent.width
            height: parent.height
            visible: stuff.selected
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 0
        Button {
            Layout.preferredWidth: height
            text: "⇥"
            font.pointSize: 20
        }
        TextField {
            id: inputField
            Layout.fillWidth: true
            font.family: "Menlo"
            font.pointSize: 16
            Layout.alignment: Qt.AlignVCenter
            verticalAlignment: TextField.AlignVCenter
            onAccepted: {
                if (text.length > 0) {
                    stuff.selected.input(text)
                    text = ""
                }
            }
            background: Rectangle {
                color: palette.base
            }
            color: palette.text
        }
        Button {
            id: imageButton
            Layout.preferredWidth: height
            property bool isBusy: false
            text: isBusy ? "" : "📷"
            enabled: !isBusy
            font.pointSize: 16
            onClicked: {
                fileDialog.open()
                isBusy = true
            }
            BusyIndicator {
                id: busy
                visible: parent.isBusy
                anchors.fill: parent
                scale: 0.7
            }
        }
    }

    Dialogs.FileDialog {
        id: fileDialog
        folder: shortcuts.pictures
        nameFilters: [ "Image files (*.jpg *.png)" ]
        onAccepted: {
            inputField.text += " " + fileUrl
            imageButton.isBusy = false
        }
    }
}