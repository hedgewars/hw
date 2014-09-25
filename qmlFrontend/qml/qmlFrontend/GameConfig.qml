import QtQuick 2.0
import Hedgewars.Engine 1.0

Rectangle {
    HWButton {
        id: btnPreview
        x: 50
        y: 66
        width: 150
        height: 150

        onClicked: {
            HWEngine.run()
        }

        Connections {
            target: HWEngine
            onPreviewImageChanged: previewImage.source = "image://preview/1"
        }
    }

    Image {
        id: previewImage
        x: 210
        y: 70
        width: 256
        height: 128
        cache: false
    }
}
