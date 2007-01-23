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
					arg(r.x() * 2, 4).arg(r.y() * 2, 4).arg(r.width() * 2, 4).arg(r.height() * 2, 4) << endl;
		}
		stream << "      );" << endl;
		f.close();
	}
}

void MyWindow::Save()
{
	if (xy->rects.size())
	{
		QFile f("rects.txt");
		if (!f.open(QIODevice::WriteOnly))
		{
			QMessageBox::information(this, tr("Error"),
						tr("Cannot save"));
			return ;
		}

		QTextStream stream(&f);
		for(int i = 0; i < xy->rects.size(); i++)
		{
			QRect r = xy->rects[i].normalized();
			stream << r.x() << " " << r.y() << " " << r.width() << " " << r.height() << endl;
		}
		f.close();
	}
}

void MyWindow::Load()
{

}
