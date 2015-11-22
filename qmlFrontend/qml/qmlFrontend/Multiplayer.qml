import QtQuick 2.0
import Hedgewars.Engine 1.0

Item {
    GameConfig {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: btnRunGame.top
    }

    HWButton {
        id: btnBack
        width: 40
        height: 40
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        onClicked: pages.currentPage = "LocalGame"
    }

    HWButton {
        id: btnRunGame
        width: 40
        height: 40
        anchors.bottom: parent.bottom
        anchors.right: parent.right

        onClicked: HWEngine.runLocalGame()
    }
}

