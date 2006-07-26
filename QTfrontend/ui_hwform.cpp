#include <QVBoxLayout>
#include <QGridLayout>
#include "ui_hwform.h"
#include "pages.h"

void Ui_HWForm::setupUi(QMainWindow *HWForm)
{
	SetupFonts();

	HWForm->setObjectName(QString::fromUtf8("HWForm"));
	HWForm->resize(QSize(620, 430).expandedTo(HWForm->minimumSizeHint()));
	HWForm->setMinimumSize(QSize(620, 430));
	HWForm->setWindowTitle(QMainWindow::tr("-= by unC0Rr =-"));
	centralWidget = new QWidget(HWForm);
	centralWidget->setObjectName(QString::fromUtf8("centralWidget"));

	centralWidget = new QWidget(HWForm);
	centralWidget->setObjectName(QString::fromUtf8("centralWidget"));

	SetupPages(centralWidget);

	HWForm->setCentralWidget(centralWidget);

	Pages->setCurrentIndex(0);

	QMetaObject::connectSlotsByName(HWForm);
}

void Ui_HWForm::SetupFonts()
{
	font14 = new QFont("MS Shell Dlg", 14);
}

void Ui_HWForm::SetupPages(QWidget *Parent)
{
	Pages =	new QStackedLayout(Parent);

	pageLocalGame = new PageLocalGame();
	Pages->addWidget(pageLocalGame);

	pageEditTeam = new PageEditTeam();
	Pages->addWidget(pageEditTeam);

	pageOptions = new PageOptions();
	Pages->addWidget(pageOptions);

	pageMultiplayer = new PageMultiplayer();
	Pages->addWidget(pageMultiplayer);

	pagePlayDemo =	new PagePlayDemo();
	Pages->addWidget(pagePlayDemo);

	pageNet = new PageNet();
	Pages->addWidget(pageNet);

	pageNetChat	= new PageNetChat();
	Pages->addWidget(pageNetChat);

	pageNetGame	= new PageNetGame();
	Pages->addWidget(pageNetGame);

	pageMain = new PageMain();
	Pages->addWidget(pageMain);
}
