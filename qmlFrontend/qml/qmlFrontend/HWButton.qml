import QtQuick 2.0

Rectangle {
    id: hwbutton
    width: 360
    height: 360
    color: "#15193a"
    radius: 8
    border.width: 4
    border.color: "#ea761d"
    opacity: 1

    signal clicked()

    MouseArea {
        id: mousearea
        anchors.fill: parent
        hoverEnabled: true
        onEntered: parent.border.color = "#eaea00"
        onExited: parent.border.color = "#ea761d"
        onClicked: hwbutton.clicked()
    }
}
