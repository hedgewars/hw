import QtQuick 2.7
import Hedgewars.Engine 1.0

Page1Form {
  gameButton.onClicked: {
    HWEngine.runQuickGame()
}
  button1.onClicked: {
    HWEngine.getPreview()
  }

  Connections {
      target: HWEngine
      onPreviewImageChanged: {
          previewImage.source = "image://preview/image"
      }
      onPreviewIsRendering: {
        console.log("==========")
          previewImage.source = "qrc:/res/iconTime.png"
      }
      onPreviewHogCountChanged: {
      }
  }

}
