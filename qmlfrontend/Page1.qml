import QtQuick 2.7
import Hedgewars.Engine 1.0

Page1Form {
  tickButton.onClicked: {
    gameView.tick(100)
  }
  gameButton.onClicked: {
    var engineInstance = HWEngine.runQuickGame()
    gameView.engineInstance = engineInstance
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
      previewImage.source = "qrc:/res/iconTime.png"
    }
  }
}
