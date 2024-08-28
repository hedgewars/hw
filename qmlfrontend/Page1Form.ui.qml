import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Hedgewars.Engine 1.0

Item {
  id: element
  property alias button1: button1
  property alias previewImage: previewImage
  property alias preview: preview
  property alias gameButton: gameButton
  property alias netButton: netButton
  property alias tickButton: tickButton
  property alias gameView: gameView
  property alias gameMouseArea: gameMouseArea

  ColumnLayout {
    anchors.fill: parent

    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      Layout.fillHeight: false

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

    Rectangle {
      id: preview
      border.color: "orange"
      border.width: 5
      radius: 5

      Layout.minimumHeight: 256
      Layout.fillWidth: true

      gradient: Gradient {
        GradientStop {
          position: 0
          color: "lightblue"
        }
        GradientStop {
          position: 0.9
          color: "blue"
        }
        GradientStop {
          position: 0.9
          color: "darkblue"
        }
        GradientStop {
          position: 1.0
          color: "darkblue"
        }
      }

      Image {
        id: previewImage

        anchors.fill: parent
        anchors.margins: parent.radius
        source: "qrc:/res/iconTime.png"
        fillMode: Image.PreserveAspectFit
        cache: false
      }
    }

    GameView {
      id: gameView

      Layout.fillWidth: true
      Layout.fillHeight: true

      MouseArea {
        id: gameMouseArea
        anchors.fill: parent

        property point lastPoint
      }
    }
  }

  Button {
    id: netButton
    text: qsTr("Net")
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 8
    anchors.left: parent.left
    anchors.leftMargin: 8
  }
}
