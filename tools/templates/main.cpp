#include <QApplication>

#include "mainform.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    MyWindow *mainWin = new MyWindow;
    mainWin->show();
    return app.exec();
}
