import QtQuick 2.0

Rectangle {
    id: pages
    width: 800
    height: 600

    property variant pagesList  : [
        "First"
        , "LocalGame"
        , "GameConfig"
        , "Connect"
    ];

    property string  currentPage : "First";

    Repeater {
        model: pagesList;

        delegate: Loader {
            active: false
            asynchronous: true
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
}
