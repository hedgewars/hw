import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
  visible: true
  width: 640
  height: 480
  title: qsTr("Hello World")

  SwipeView {
    id: swipeView
    anchors.fill: parent

    Page1 {
    }
  }
}
