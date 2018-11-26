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
  property alias gameView: gameView

  ColumnLayout {
    anchors.fill: parent

    RowLayout {
      Layout.alignment: Qt.AlignHCenter

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
    }
  }
}
