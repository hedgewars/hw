import QtQuick 2.0
import Hedgewars.Engine 1.0

Rectangle {
    HWButton {
        id: btnPreview
        x: 50
        y: 16
        width: 256
        height: 128

        onClicked: HWEngine.getPreview()

        Connections {
            target: HWEngine
            onPreviewImageChanged: previewImage.source = "image://preview/" + HWEngine.currentSeed()
        }

        Image {
            id: previewImage
            x: 0
            y: 0
            width: 256
            height: 128
            cache: false
        }
    }

    Rectangle {
        x: 320
        y: 16
        width: 100
        height: 256
        color: "#15193a"
        radius: 8
        border.width: 4
        border.color: "#eaea00"
        Image {
            id: themeImage
            x: 0
            y: 0
            width: 64
            height: 64
            fillMode: Image.Pad
        }

        ListView {
            id: themesList
            x: 0
            y: 64
            width: 100
            height: 192
            highlight: Rectangle { color: "#eaea00"; radius: 4 }
            focus: true

            model: themesModel
            delegate: Rectangle {
                height: 25
                width: 100
                color: "transparent"
                Text {id: themeName; text: modelData }
                MouseArea {
                     z: 1
                     anchors.fill: parent
                     onClicked: {
                         themeImage.source = "image://theme/" + themeName.text
                         themesList.currentIndex = index
                     }
                }
            }
        }
    }
}
