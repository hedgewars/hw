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

      Label {
        text: "Gen: %1".arg(tracer.generation)
      }
    }
  }

  FileDialog {
    id: fileDialog

    nameFilters: ["Hedgehog images (*.png)"]

    onAccepted: {
      console.log("Hello");
      baseImage.source = selectedFile;
      tracer.start(fileDialog.selectedFile);
      tracer.generation = 0;
    }
  }

  Tracer {
    id: tracer

    property int generation: 0

    atoms: [
      {
        "type": "polygon",
        "length": 3,
        "pens": ["#9f086e", "#54a2fa"],
        "brushes": ["#2c78d2", "#54a2fa"]
      },
      {
        "type": "circle",
        "pens": ["#9f086e", "#f29ce7"],
        "brushes": ["#d66bcc",  "#f29ce7"]
      },
      {
        "type": "circle",
        "pens": ["#000000"],
        "brushes": [ "#000000"]
      },
      {
        "type": "circle",
        "pens": ["#ffffff"],
        "brushes": [ "#ffffff"]
      }
    ]
  }

  Timer {
    id: stepTimer

    interval: 120
    repeat: true
    running: false
    triggeredOnStart: true

    onTriggered: {
      tracer.generation = tracer.generation + 1;
      tracer.step();
    }
  }

  Rectangle {
    anchors.fill: parent
    color: "#a0c0a0"
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
      Layout.fillHeight: true
      Layout.fillWidth: true
      columns: 30

      Repeater {
        model: tracer.solutions

        Image {
          fillMode: Image.PreserveAspectFit
          height: 32
          source: "file://" + modelData
          width: 32

          Rectangle {
            anchors.fill: parent
            border.color: "black"
            border.width: 1
            color: "transparent"
          }
        }
      }
    }
  }
}
