import QtQuick 2.0
import QtQuick.Window 2.1

HWButton {
    property alias model: itemsList.model
    property alias delegate: itemsList.delegate

    Window {
        id: selection
        visibility: Window.Hidden

        ListView {
            id: itemsList
            x: 0
            y: 64
            anchors.fill: parent
            highlight: Rectangle { color: "#eaea00"; radius: 4 }
            focus: true
        }
    }

    onClicked: selection.visibility = Window.Windowed
}
