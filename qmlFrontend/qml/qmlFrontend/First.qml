import QtQuick 2.0

Rectangle {
    HWButton {
        id: btnLocalGame
        x: 8
        y: 80
        width: 166
        height: 166

        onClicked: pages.currentPage = "LocalGame"
    }

    HWButton {
        id: btnNetwork
        x: 192
        y: 80
        width: 166
        height: 166

        onClicked: pages.currentPage = "Connect"
    }

    HWButton {
        id: btnAbout
        x: 100
        y: 16
        width: 200
        height: 50
    }
}
