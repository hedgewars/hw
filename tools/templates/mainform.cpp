#include <QGridLayout>
#include <QImage>
#include <QPixmap>
#include <QMessageBox>
#include <QFile>
#include <QTextStream>
#include <QRegExp>
#include <QDebug>
#include "mainform.h"

MyWindow::MyWindow(QWidget * parent, Qt::WFlags flags)
        : QMainWindow(parent, flags)

{
    QWidget * centralWidget = new QWidget(this);
    QGridLayout * mainlayout = new QGridLayout(centralWidget);
    mainlayout->setMargin(1);
    mainlayout->setSpacing(1);

    sa_xy = new QScrollArea(centralWidget);
    xy = new PixLabel();
    xy->setFixedSize(1024, 512);
    sa_xy->setWidget(xy);

    mainlayout->addWidget(sa_xy, 0, 0, 1, 4);

    setCentralWidget(centralWidget);

    buttAdd = new QPushButton(centralWidget);
    buttAdd->setText(tr("Add"));
    mainlayout->addWidget(buttAdd, 1, 0);

    buttCode = new QPushButton(centralWidget);
    buttCode->setText(tr("Code"));
    mainlayout->addWidget(buttCode, 1, 1);

    buttSave = new QPushButton(centralWidget);
    buttSave->setText(tr("Save"));
    mainlayout->addWidget(buttSave, 1, 3);

    buttLoad = new QPushButton(centralWidget);
    buttLoad->setText(tr("Load"));
    mainlayout->addWidget(buttLoad, 1, 2);

    connect(buttAdd, SIGNAL(clicked()), xy, SLOT(AddRect()));
    connect(buttCode, SIGNAL(clicked()), this, SLOT(Code()));
    connect(buttSave, SIGNAL(clicked()), this, SLOT(Save()));
    connect(buttLoad, SIGNAL(clicked()), this, SLOT(Load()));
}

void MyWindow::Code()
{
    if (xy->rects.size())
    {
        QFile f("template.pas");
        if (!f.open(QIODevice::WriteOnly))
        {
            QMessageBox::information(this, tr("Error"),
                        tr("Cannot save"));
            return ;
        }

        QTextStream stream(&f);
        stream << QString("const Template0Points: array[0..%1] of TSDL_Rect =").arg(xy->rects.size() - 1) << endl;
        stream << "      (" << endl;
        for(int i = 0; i < xy->rects.size(); i++)
        {
            QRect r = xy->rects[i].normalized();
            stream << QString("       (x: %1; y: %2; w: %3; h: %4),").
                    arg(r.x() * 4, 4).arg(r.y() * 4, 4).arg(r.width() * 4, 4).arg(r.height() * 4, 4) << endl;
        }
        stream << "      );" << endl;
        f.close();
    }
}

void MyWindow::Save()
{
    Code();
}

void MyWindow::Load()
{
    QFile f("template.pas");
    if (!f.open(QIODevice::ReadOnly))
    {
        QMessageBox::information(this, tr("Error"),
                    tr("Cannot open file"));
        return ;
    }

    QTextStream stream(&f);
    QStringList sl;
    while (!stream.atEnd())
    {
        sl << stream.readLine();
    }
    xy->rects.clear();
    for (int i = 0; i < sl.size(); ++i)
    {
        QRegExp re("x:\\s*(\\d+);\\sy:\\s*(\\d+);\\sw:\\s*(\\d+);\\sh:\\s*(\\d+)");
        re.indexIn(sl.at(i));
        QStringList coords = re.capturedTexts();
        qDebug() << sl.at(i) << coords;
        if ((coords.size() == 5) && (coords[0].size()))
            xy->rects.push_back(QRect(coords[1].toInt() / 4, coords[2].toInt() / 4, coords[3].toInt() / 4, coords[4].toInt() / 4));
    }
    f.close();
    xy->repaint();
}
