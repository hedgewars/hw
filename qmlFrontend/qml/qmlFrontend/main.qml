import QtQuick 2.0
import Hedgewars.Engine 1.0

Rectangle {
    width: 400
    height: 400

    HWButton {
        id: hwbutton1
        x: 8
        y: 66
        width: 166
        height: 158

        onClicked: {
            HWEngine.run()
        }

        Connections {
            target: HWEngine
            onPreviewImageChanged: previewImage.source = "image://preview/1"
        }
    }

    HWButton {
        id: hwbutton2
        x: 192
        y: 66
        width: 200
        height: 139
    }

    Image {
        id: previewImage
        x: 70
        y: 250
        width: 256
        height: 128
        cache: false
    }
}
