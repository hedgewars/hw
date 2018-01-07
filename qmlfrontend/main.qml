import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

ApplicationWindow {
  visible: true
  width: 640
  height: 480
  title: qsTr("Hello World")

  SwipeView {
    id: swipeView
    anchors.fill: parent
    currentIndex: tabBar.currentIndex

    Page1 {
    }
  }
}
