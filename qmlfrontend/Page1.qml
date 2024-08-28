import QtQuick
import Hedgewars.Engine 1.0

Page1Form {
  property HWEngine hwEngine
  property var keyBindings: ({
      "long": {
        [Qt.Key_Space]: Engine.Attack,
        [Qt.Key_Up]: Engine.ArrowUp,
        [Qt.Key_Right]: Engine.ArrowRight,
        [Qt.Key_Down]: Engine.ArrowDown,
        [Qt.Key_Left]: Engine.ArrowLeft,
        [Qt.Key_Shift]: Engine.Precision
      },
      "simple": {
        [Qt.Key_Tab]: Engine.SwitchHedgehog,
        [Qt.Key_Enter]: Engine.LongJump,
        [Qt.Key_Backspace]: Engine.HighJump,
        [Qt.Key_Y]: Engine.Accept,
        [Qt.Key_N]: Engine.Deny
      }
    })
  property NetSession netSession

  focus: true

  Component.onCompleted: {
    hwEngine = hwEngineComponent.createObject();
  }
  Keys.onPressed: event => {
    if (event.isAutoRepeat) {
      return;
    }
    let action = keyBindings["simple"][event.key];
    if (action !== undefined) {
      gameView.engineInstance.simpleEvent(action);
      event.accepted = true;
      return;
    }
    action = keyBindings["long"][event.key];
    if (action !== undefined) {
      gameView.engineInstance.longEvent(action, Engine.Set);
      event.accepted = true;
    }
  }
  Keys.onReleased: event => {
    if (event.isAutoRepeat) {
      return;
    }
    const action = keyBindings["long"][event.key];
    if (action !== undefined) {
      gameView.engineInstance.longEvent(action, Engine.Unset);
      event.accepted = true;
    }
  }
  netButton.onClicked: {
    netSession = netSessionComponent.createObject();
    netSession.open();
  }

  Component {
    id: hwEngineComponent

    HWEngine {
      dataPath: "../share/hedgewars/Data"
      engineLibrary: "../rust/lib-hedgewars-engine/target/debug/libhedgewars_engine.so"
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

  tickButton {
    onClicked: {
      tickButton.visible = false;
    }
  }

  Timer {
    id: advancingTimer

    interval: 100
    repeat: true
    running: !tickButton.visible

    onTriggered: {
      gameView.tick(100);
      gameView.update();
    }
  }

  gameButton {
    visible: !gameView.engineInstance

    onClicked: {
      const engineInstance = hwEngine.runQuickGame();
      gameView.engineInstance = engineInstance;
    }
  }

  button1 {
    visible: !gameView.engineInstance

    onClicked: {
      hwEngine.getPreview();
    }
  }

  preview {
    visible: !gameView.engineInstance
  }

  gameMouseArea {
    onPositionChanged: event => {
      gameView.engineInstance.moveCamera(Qt.point(event.x - gameMouseArea.lastPoint.x, event.y - gameMouseArea.lastPoint.y));
      gameMouseArea.lastPoint = Qt.point(event.x, event.y);
    }
    onPressed: event => {
      gameMouseArea.lastPoint = Qt.point(event.x, event.y);
    }
  }
}
