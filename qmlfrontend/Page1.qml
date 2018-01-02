import QtQuick 2.7
import Hedgewars.Engine 1.0

Page1Form {
  tickButton.onClicked: {
    item1.tick(100);
}
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
          previewImage.source = "qrc:/res/iconTime.png"
      }
      onPreviewHogCountChanged: {
      }
  }
}
