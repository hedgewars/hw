#include <QtGui/QGuiApplication>
#include <QQmlEngine>

#include "qtquick2applicationviewer/qtquick2applicationviewer.h"
#include "hwengine.h"
#include "previewimageprovider.h"


int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    HWEngine::exposeToQML();

    QtQuick2ApplicationViewer viewer;

    viewer.engine()->addImageProvider(QLatin1String("preview"), new PreviewImageProvider());

    viewer.setMainQmlFile(QStringLiteral("qml/qmlFrontend/main.qml"));
    viewer.showExpanded();

    return app.exec();
}
