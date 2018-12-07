import QtQuick 2.7
import Hedgewars.Engine 1.0

Page1Form {
  property var hwEngine

  Component {
    id: hwEngineComponent

    HWEngine {
      engineLibrary: "./libhedgewars_engine.so"
      previewAcceptor: PreviewAcceptor
      onPreviewImageChanged: previewImage.source = "image://preview/image"
      onPreviewIsRendering: previewImage.source = "qrc:/res/iconTime.png"
    }
  }

  Component.onCompleted: {
    hwEngine = hwEngineComponent.createObject()
  }

  tickButton.onClicked: {
    gameView.tick(100)
  }
  gameButton.onClicked: {
    var engineInstance = hwEngine.runQuickGame()
    gameView.engineInstance = engineInstance
  }
  button1.onClicked: {
    hwEngine.getPreview()
  }
}
