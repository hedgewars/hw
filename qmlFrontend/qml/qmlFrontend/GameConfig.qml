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

    ListView {
        x: 330
        y: 16
        width: 100; height: 100

        model: themesModel
        delegate: Rectangle {
            height: 25
            width: 100
            Text { text: modelData }
        }
    }
}
