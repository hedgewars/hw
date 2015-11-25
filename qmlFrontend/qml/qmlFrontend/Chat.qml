import QtQuick 2.0
import Hedgewars.Engine 1.0

Rectangle {
    color: "#15193a"
    radius: 8
    border.width: 4
    border.color: "#ea761d"

    ListView {
        id: chatLines
        x: 0
        width: parent.width - clientsList.width
        anchors.top: parent.top
        anchors.bottom: input.top
        focus: true
        clip: true
        highlightFollowsCurrentItem: true

        model: ListModel {
            id: chatLinesModel
        }

        delegate: Rectangle {
            id: chatLinesDelegate
            height: 24
            width: parent.width
            color: "transparent"

            Row {
                spacing: 8;
                Text {
                    color: "#ffffa0"
                    text: nick

                    MouseArea {
                         z: 1
                         anchors.fill: parent
                         onClicked: ;
                    }
                }
                Text {
                    color: "#ffffff"
                    text: line

                    MouseArea {
                         z: 1
                         anchors.fill: parent
                         onClicked: ;
                    }
                }
            }

        }

        function addLine(nickname, line) {
            chatLinesModel.append({"nick" : nickname, "line": line})
            if(chatLinesModel.count > 200)
                chatLinesModel.remove(0)
            chatLines.currentIndex = chatLinesModel.count - 1
        }
    }

    TextInput {
        id: input
        x: 0
        width: chatLines.width
        height: 24
        anchors.bottom: parent.bottom
        color: "#eccd2f"

        onAccepted: {
            HWEngine.sendChatMessage(text)
            chatLines.addLine(HWEngine.myNickname(), text)
            text = ""
        }
    }

    ListView {
        id: clientsList
        x: parent.width - width
        width: 100
        height: parent.height
        focus: true
        clip: true

        model: ListModel {
            id: chatClientsModel
        }

        delegate: Rectangle {
            id: chatClientDelegate
            height: 24
            width: parent.width
            color: "transparent"

            Row {
                Text {
                    color: "#ffffff"
                    text: name

                    MouseArea {
                         z: 1
                         anchors.fill: parent
                         onClicked: ;
                    }
                }
            }

        }
    }

    function addChatLine(nickname, line) {
        chatLines.addLine(nickname, line)
    }

    function addClient(clientName) {
        chatClientsModel.append({"isAdmin": false, "name": clientName})
        chatLines.addLine("***", qsTr("%1 joined").arg(clientName))
    }

    function removeClient(clientName, reason) {
        var i = chatClientsModel.count - 1;
        while ((i >= 0) && (chatClientsModel.get(i).name !== clientName)) --i;

        if(i >= 0) {
            chatClientsModel.remove(i, 1);
            chatLines.addLine("***", qsTr("%1 quit (%2)").arg(clientName).arg(reason))
        }
    }
}


