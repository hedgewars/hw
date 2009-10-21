#include <QtGui/QApplication>
#include "editor.h"

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    editor w;
    w.show();
    return a.exec();
}
