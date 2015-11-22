import QtQuick 2.0
import Hedgewars.Engine 1.0

Rectangle {
    HWButton {
        id: btnQuickGame
        x: 8
        y: 66
        width: 150
        height: 150

        onClicked: HWEngine.runQuickGame()
    }

    HWButton {
        id: btnMultiplayer
        x: 192
        y: 66
        width: 150
        height: 150

        onClicked: pages.currentPage = "Multiplayer"
    }

    HWButton {
        id: btnBack
        width: 40
        height: 40
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        onClicked: pages.currentPage = "First"
    }
}
