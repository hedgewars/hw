import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

import Hedgewars.Engine 1.0

Item {
    property alias button1: button1
    property alias previewImage: previewImage
    property alias gameButton: gameButton
    width: 1024
    height: 800
    property alias tickButton: tickButton
    property alias item1: item1

    RowLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 20
        anchors.top: parent.top

        Button {
            id: button1
            text: qsTr("Preview")
        }

        Button {
            id: gameButton
            text: qsTr("Game")
        }

        Button {
            id: tickButton
            text: qsTr("Tick")
        }
    }

    Image {
        id: previewImage
        x: 8
        y: 20
        width: 256
        height: 128
        source: "qrc:/res/iconTime.png"
        cache: false
    }

    GameView {
        id: item1
        x: 8
        y: 154
        width: 1008
        height: 638
    }
}
