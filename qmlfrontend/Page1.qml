import QtQuick
import Hedgewars.Engine 1.0

Page1Form {
  focus: true

  property HWEngine hwEngine
  property NetSession netSession

  Component {
    id: hwEngineComponent

    HWEngine {
      engineLibrary: "../rust/lib-hedgewars-engine/target/debug/libhedgewars_engine.so"
      dataPath: "../share/hedgewars/Data"
      previewAcceptor: PreviewAcceptor
      onPreviewImageChanged: previewImage.source = "image://preview/image"
      onPreviewIsRendering: previewImage.source = "qrc:/res/iconTime.png"
    }
  }

  Component {
    id: netSessionComponent

    NetSession {
      nickname: "test0272"
      url: "hwnet://gameserver.hedgewars.org:46632"
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
      const engineInstance = hwEngine.runQuickGame()
      gameView.engineInstance = engineInstance
    }
  }
  button1 {
    visible: !gameView.engineInstance
    onClicked: {
      hwEngine.getPreview()
    }
  }
  preview {
    visible: !gameView.engineInstance
  }

  netButton.onClicked: {
    netSession = netSessionComponent.createObject()
    netSession.open()
  }

  Keys.onPressed: {
    if (event.key === Qt.Key_Enter)
      gameView.engineInstance.longEvent(Engine.Attack, Engine.Set)
  }

  Keys.onReleased: {
    if (event.key === Qt.Key_Enter)
      gameView.engineInstance.longEvent(Engine.Attack, Engine.Unset)
  }

  gameMouseArea {
    onPressed: event => {
                 gameMouseArea.lastPoint = Qt.point(event.x, event.y)
               }
    onPositionChanged: event => {
                         gameView.engineInstance.moveCamera(
                           Qt.point(event.x - gameMouseArea.lastPoint.x,
                                    event.y - gameMouseArea.lastPoint.y))

                         gameMouseArea.lastPoint = Qt.point(event.x, event.y)
                       }
  }
}
