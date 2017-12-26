import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

Item {
  property alias button1: button1
  property alias previewImage: previewImage
  property alias gameButton: gameButton

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
    }

    Image {
        id: previewImage
        x: 188
        y: 176
        width: 256
        height: 128
        source: "qrc:/res/iconTime.png"
        cache: false
    }
}
