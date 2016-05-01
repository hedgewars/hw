import QtQuick 2.0

Rectangle {
    id: hwbutton
    width: 360
    height: 360
    color: "#15193a"
    radius: 8
    border.width: 4
    opacity: 1

    signal clicked()

    Behavior on border.color {
        ColorAnimation {}
    }

    MouseArea {
        id: mousearea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: parent.clicked()
    }

    states: [
        State {
            when: mousearea.containsMouse

            PropertyChanges {
                target: hwbutton
                border.color: "#eaea00"
            }
        }
        , State {
            when: !mousearea.containsMouse

            PropertyChanges {
                target: hwbutton
                border.color: "#ffcc00"
            }
    }]
}
