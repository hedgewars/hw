import QtQuick 2.0
import Hedgewars.Engine 1.0

Rectangle {
    HWButton {
        id: btnBack
        width: 40
        height: 40
        anchors.left: parent.left
        anchors.bottom: parent.bottom

        onClicked: HWEngine.partRoom("")
    }

    GameConfig {
        id: gameConfig
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: roomChat.top
    }

    Chat {
        id: roomChat;
        x: 0;
        width: parent.width;
        height: 250;
        anchors.bottom: btnBack.top

        Connections {
            target: HWEngine
            onRoomChatLine: roomChat.addChatLine(nickname, line)
            onRoomClientAdded: roomChat.addClient(clientName)
            onRoomClientRemoved: roomChat.removeClient(clientName, reason)
        }
    }
}
