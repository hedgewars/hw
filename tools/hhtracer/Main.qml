import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

ApplicationWindow {
  height: 900
  title: qsTr("Tracer")
  visible: true
  width: 1200

  header: ToolBar {
    RowLayout {
      Button {
        text: qsTr("Choose Image...")

        onClicked: fileDialog.open()
      }

      Button {
        text: qsTr("Start")

        onClicked: {
          stepTimer.start();
        }
      }

      Button {
        text: qsTr("Stop")

        onClicked: {
          stepTimer.stop();
        }
      }

      Label {
        text: "Best: %1".arg(tracer.bestSolution)
      }
    }
  }

  FileDialog {
    id: fileDialog

    nameFilters: ["Hedgehog images (*.png)"]

    onAccepted: {
      console.log("Hello")
      baseImage.source = selectedFile;
      tracer.start(fileDialog.selectedFile);
    }
  }

  Tracer {
    id: tracer
  }


  Timer {
    id: stepTimer

    interval: 120
    repeat: true
    running: false
    triggeredOnStart: true

    onTriggered: tracer.step()
  }

  ColumnLayout {
    anchors.fill: parent

    Image {
      id: baseImage

      Layout.fillWidth: true
      Layout.preferredHeight: 32
      fillMode: Image.PreserveAspectFit
    }

    GridLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      columns: 50

      Repeater {
        model: tracer.solutions

        Image {
          width: 32
          height: 32
          source: "file://" + modelData
          fillMode: Image.PreserveAspectFit

          Rectangle {
            border.width: 1
            border.color: "black"
            color: "transparent"
            anchors.fill: parent
          }
        }
      }
    }
  }
}
