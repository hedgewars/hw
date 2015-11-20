import QtQuick 2.0
import Hedgewars.Engine 1.0

Rectangle {
    ListView {
        id: roomsList
        x: 20
        y: 0
        width: parent.width
        height: parent.height - x
        focus: true
        clip: true

        model: ListModel {
            id: roomsListModel
        }

        delegate: Rectangle {
            id: roomDelegate
            height: 24
            width: parent.width
            color: "transparent"

            Row {
                spacing: 8;
                Text {
                    text: name
                }
                Text {
                    text: players + " / " + teams
                }
                Text {
                    text: host
                }
                Text {
                    text: map
                }
                Text {
                    text: script
                }
                Text {
                    text: scheme
                }
                Text {
                    text: weapons
                }
            }

            MouseArea {
                 z: 1
                 anchors.fill: parent
                 onClicked: ;
            }
        }

        Connections {
            target: HWEngine
            onRoomAdded: roomsListModel.append({
                               "name" : name
                               , "players": players
                               , "teams": teams
                               , "host": host
                               , "map": map
                               , "script": script
                               , "scheme": scheme
                               , "weapons": weapons
                           })
            onRoomRemoved: {
                var i = roomsListModel.count - 1;
                while ((i >= 0) && (roomsListModel.get(i).name !== name)) --i

                if(i >= 0) roomsListModel.remove(i, 1)
            }
        }
    }

    Chat {
        id: lobbyChat;
        x: 0;
        y: 100;
        width: parent.width;
        height: parent.height - y;
    }
}


