import QtQuick 2.0
import Hedgewars.Engine 1.0


Rectangle {
    Column {
        spacing: 8

    HWButton {
        id: btnPreview
        // this, as well as the positions of images, seems to have the border thickness (3px) into account
        width: 262
        height: 134

        onClicked: HWEngine.getPreview()

        Connections {
            target: HWEngine
            onPreviewImageChanged: {
                previewImage.visible = true
                previewImage.source = "image://preview/image"
                previewWaitImage.visible = false
            }
            onPreviewIsRendering: {
                previewImage.source = ""
                previewImage.visible = false
                previewWaitImage.visible = true
            }
        }

        Image {
            id: previewBackground
            x: 3
            y: 3
            width: 256
            height: 128
            cache: true
            source: "qrc:/res/prevBg.png"
        }

        Image {
            id: previewImage
            x: 3
            y: 3
            width: 256
            height: 128
            cache: false
            source: ""
        }

        Image {
            id: previewWaitImage
            x: 117
            y: 53
            width: 26
            height: 26
            cache: true
            source: "qrc:/res/iconTime.png"
        }

        Image {
            id: hogCountBackground
            x: 216
            y: 6
            width: 41
            height: 21
            cache: true
            source: "qrc:/res/hogCntBg.png"
        }

        Text {
            id: hogCount
            x: 230
            y: 10
            text: "?"
            horizontalAlignment: Text.AlignHRight
            font.family: "MS Shell Dlg"
            font.pixelSize: 12
            color: "#ffcc00"
        }
    }

    HWComboBox {
        id: cbTheme
        width: 256
        height: 64

        model: themesModel
        delegate: Rectangle {
            height: 25
            width: 100
            color: "transparent"

            property alias itemIconSource: themeIcon.source
            property alias itemText: themeName.text

            Row {
                Image {id: themeIcon; width: height; height: parent.height; source: "image://theme/" + modelData}
                Text {id: themeName; text: modelData }
            }

            MouseArea {
                 z: 1
                 anchors.fill: parent
                 onClicked: {
                     cbTheme.currentIndex = index
                     HWEngine.setTheme(themeName.text)
                 }
            }
        }

        Connections {
            target: HWEngine
            onThemeChanged: cbTheme.showItem({"iconSource" : "image://theme/" + theme, "text" : theme});
        }
    }

    HWComboBox {
        id: cbScript
        width: 256
        height: 32

        model: scriptsModel
        delegate: Rectangle {
            height: 25
            width: 100
            color: "transparent"

            property string itemIconSource: ""
            property alias itemText: scriptName.text

            Row {
                //Image {id: themeIcon; width: height; height: parent.height; source: "image://theme/" + modelData}
                Text {id: scriptName; text: modelData }
            }

            MouseArea {
                 z: 1
                 anchors.fill: parent
                 onClicked: {
                     cbScript.currentIndex = index
                     HWEngine.setScript(scriptName.text)
                 }
            }
        }
        Connections {
            target: HWEngine
            onScriptChanged: cbScript.showItem({"iconSource" : "", "text" : script});
        }
    }

    HWComboBox {
        id: cbScheme
        width: 256
        height: 32

        model: schemesModel
        delegate: Rectangle {
            height: 25
            width: 100
            color: "transparent"

            property string itemIconSource: ""
            property alias itemText: schemeName.text

            Row {
                //Image {id: themeIcon; width: height; height: parent.height; source: "image://theme/" + modelData}
                Text {id: schemeName; text: modelData }
            }

            MouseArea {
                 z: 1
                 anchors.fill: parent
                 onClicked: {
                     cbScheme.currentIndex = index
                     HWEngine.setScheme(schemeName.text)
                 }
            }
        }
        Connections {
            target: HWEngine
            onSchemeChanged: cbScheme.showItem({"iconSource" : "", "text" : scheme});
        }
    }


    HWComboBox {
        id: cbAmmo
        width: 256
        height: 32

        model: ammosModel
        delegate: Rectangle {
            height: 25
            width: 100
            color: "transparent"

            property string itemIconSource: ""
            property alias itemText: ammoName.text

            Row {
                //Image {id: themeIcon; width: height; height: parent.height; source: "image://theme/" + modelData}
                Text {id: ammoName; text: modelData }
            }

            MouseArea {
                 z: 1
                 anchors.fill: parent
                 onClicked: {
                     cbAmmo.currentIndex = index
                     HWEngine.setAmmo(ammoName.text)
                 }
            }
        }
        Connections {
            target: HWEngine
            onAmmoChanged: cbAmmo.showItem({"iconSource" : "", "text" : ammo});
        }
    }
    }

    ListView {
        id: playingTeamsList
        x: 440
        y: 16
        width: 100
        height: 192
        highlight: Rectangle { color: "#eaea00"; radius: 4 }
        focus: true
        clip: true

        model: ListModel {
            id: playingTeamsModel
        }

        delegate: Rectangle {
            id: teamDelegate
            height: 24
            width: parent.width
            radius: 8
            border.width: 2
            border.color: "#eaea00"

            Row {
                Rectangle {
                    height: 20
                    width: height
                    color: teamColor
                    border.width: 2
                    border.color: "#eaea00"                    

                    MouseArea {
                        z: 1
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: {
                            if (mouse.button === Qt.LeftButton)
                                HWEngine.changeTeamColor(name, 1)
                            else if (mouse.button === Qt.RightButton)
                                HWEngine.changeTeamColor(name, -1)
                        }
                        onWheel: HWEngine.changeTeamColor(name, -wheel.angleDelta.y)
                   }
                }

                Text {
                    text: name
                    MouseArea {
                        z: 1
                        anchors.fill: parent
                        onClicked: HWEngine.tryRemoveTeam(name)
                   }
                }

                Text {
                    text: hedgehogsNumber
                }
            }


        }

        Connections {
            target: HWEngine
            onPlayingTeamAdded: playingTeamsModel.append({
                                                             "aiLevel": aiLevel
                                                             , "name": teamName
                                                             , "local": isLocal
                                                             , "hedgehogsNumber" : 4
                                                             , "teamColor": "#000000"
                                                         })
            onPlayingTeamRemoved: {
                var i = playingTeamsModel.count - 1;
                while ((i >= 0) && (playingTeamsModel.get(i).name !== teamName)) --i

                if(i >= 0) playingTeamsModel.remove(i, 1)
            }
            onTeamColorChanged: {
                var i = playingTeamsModel.count - 1;
                while ((i >= 0) && (playingTeamsModel.get(i).name !== teamName)) --i

                if(i >= 0) playingTeamsModel.setProperty(i, "teamColor", colorValue)
            }
            onHedgehogsNumberChanged: {
                var i = playingTeamsModel.count - 1;
                while ((i >= 0) && (playingTeamsModel.get(i).name !== teamName)) --i

                if(i >= 0) playingTeamsModel.setProperty(i, "hedgehogsNumber", hedgehogsNumber)
            }
        }
    }

    ListView {
        id: localTeamsList
        x: 440
        y: 224
        width: 100
        height: 192
        highlight: Rectangle { color: "#eaea00"; radius: 4 }
        focus: true
        clip: true

        model: ListModel {
            id: localTeamsModel
        }

        delegate: Rectangle {
            id: localTeamDelegate
            height: 24
            width: parent.width
            radius: 8
            border.width: 2
            border.color: "#eaea00"

            Row {
                Text { text: name }
            }

            MouseArea {
                 z: 1
                 anchors.fill: parent
                 onClicked: HWEngine.tryAddTeam(name)
            }
        }

        Connections {
            target: HWEngine
            onLocalTeamAdded: localTeamsModel.append({"aiLevel": aiLevel, "name": teamName})
            onLocalTeamRemoved: {
                var i = localTeamsModel.count - 1;
                while ((i >= 0) && (localTeamsModel.get(i).name !== teamName)) --i

                if(i >= 0) localTeamsModel.remove(i, 1)
            }
        }
    }

    Component.onCompleted: {
        HWEngine.resetGameConfig()
        HWEngine.getTeamsList()
        HWEngine.getPreview()
    }
}
