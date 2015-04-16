import QtQuick 2.0
import Hedgewars.Engine 1.0

Rectangle {
    HWButton {
        id: btnNetConnect
        x: 80
        y: 80
        width: 256
        height: 128

        onClicked: HWEngine.connect("netserver.hedgewars.org", 46631);
    }
}
