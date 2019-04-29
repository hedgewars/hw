import QtQuick 2.7
import Hedgewars.Engine 1.0

Page1Form {
  focus: true

  property HWEngine hwEngine

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

  tickButton {
    onClicked: {
      tickButton.visible = false
      gameView.tick(100)
    }
  }
  gameButton {
    visible: !gameView.engineInstance
    onClicked: {
      var engineInstance = hwEngine.runQuickGame()
      gameView.engineInstance = engineInstance
    }
  }
  button1 {
    visible: !gameView.engineInstance
    onClicked: {
      hwEngine.getPreview()
    }
  }

  Keys.onPressed: {
    if (event.key === Qt.Key_Enter)
      gameView.engineInstance.longEvent(EngineInstance.Attack,
                                        EngineInstance.Set)
  }

  Keys.onReleased: {
    if (event.key === Qt.Key_Enter)
      gameView.engineInstance.longEvent(EngineInstance.Attack,
                                        EngineInstance.Unset)
  }
}
