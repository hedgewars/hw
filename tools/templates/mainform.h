#include <QScrollArea>
#include <QMainWindow>
#include <QLabel>
#include <QListWidget>
#include <QPushButton>
#include "pixlabel.h"

class MyWindow : public QMainWindow
{
    Q_OBJECT

public:

    MyWindow(QWidget * parent = 0, Qt::WFlags flags = 0);

private:

    QScrollArea * sa_xy;
    PixLabel * xy;
    QPushButton * buttAdd;
    QPushButton * buttCode;
    QPushButton * buttSave;
    QPushButton * buttLoad;

private slots:
    void Code();
    void Save();
    void Load();
};
