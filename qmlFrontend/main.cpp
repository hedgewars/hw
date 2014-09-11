#include <QtGui/QGuiApplication>
#include "qtquick2applicationviewer/qtquick2applicationviewer.h"

#include "hwengine.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    HWEngine::exposeToQML();

    QtQuick2ApplicationViewer viewer;
    viewer.setMainQmlFile(QStringLiteral("qml/qmlFrontend/main.qml"));
    viewer.showExpanded();

    return app.exec();
}
