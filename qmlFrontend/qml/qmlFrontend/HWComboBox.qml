import QtQuick 2.0
import QtQuick.Window 2.1

HWButton {
    property alias model: itemsList.model
    property alias delegate: itemsList.delegate
    property alias currentIndex: itemsList.currentIndex

    Window {
        id: selection
        visibility: Window.Hidden
        modality: Qt.WindowModal
        flags: Qt.Dialog

        ListView {
            id: itemsList
            x: 0
            y: 64
            anchors.fill: parent
            anchors.bottomMargin: 32
            highlight: Rectangle { color: "#eaea00"; radius: 4 }
            focus: true

            onCurrentItemChanged: {
                cbIcon.source = currentItem.itemIconSource
                cbText.text = currentItem.itemText
            }
        }

        HWButton {
            x: parent.width - 32
            y: parent.height - 32
            width: 32
            height: 32

            onClicked: selection.visibility = Window.Hidden;
        }
    }

    Row {
        anchors.fill: parent
        anchors.margins: 4

        Image {
            id: cbIcon
            width: height
            height: parent.height
        }

        Text {
            id: cbText
            height: parent.height
            color: "#f3e520"
        }
    }

    onClicked: selection.visibility = Window.Windowed
}
