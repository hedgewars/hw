import QtQuick 2.0
import Hedgewars.Engine 1.0

Rectangle {
    id: pages
    width: 800
    height: 600

    property variant pagesList : [
        "First"
        , "LocalGame"
        , "GameConfig"
        , "Connect"
        , "Lobby"
        , "Room"
    ];

    property string  currentPage : "First";

    Repeater {
        id: pagesView
        model: pagesList

        function loadPage(page) {
            // somehow load the page (when Loader has asynchronous == true)
        }

        delegate: Loader {
            active: false
            asynchronous: false
            anchors.fill: parent
            visible: (currentPage === modelData)
            source: "%1.qml".arg(modelData)
            onVisibleChanged:      loadIfNotLoaded();
            Component.onCompleted: loadIfNotLoaded();

            function loadIfNotLoaded ()
            {
                if (visible && !active)
                    active = true;
            }
        }
    }

    Rectangle {
        id: warningsBox
        y: parent.height - height
        width: parent.width - 120
        height: 80
        anchors.horizontalCenter: parent.horizontalCenter
        color: "#7e3232"
        border.color: "#d3ec2d"
        visible: false
        z: 2

        function showMessage(message) {
            msgBox.text = message
            visible = true
        }

        Text {
            id: msgBox
            x: 0
            y: 0
            height: parent.height
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }
        HWButton {
            id: closeButton
            x: parent.width - width
            y: 0
            width: 40
            height: 40
            onClicked: warningsBox.visible = false
        }
    }

    Connections {
        target: HWEngine
        onNetConnected: {
            pagesView.loadPage("Lobby");
            pagesView.loadPage("Room");
        }
        onMovedToLobby: currentPage = "Lobby";
        onMovedToRoom: currentPage = "Room";
        onNetDisconnected: currentPage = "First";
        onWarningMessage: warningsBox.showMessage(message);
        onErrorMessage: warningsBox.showMessage(message);
    }
}
