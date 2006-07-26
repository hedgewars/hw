#ifndef UI_HWFORM_H
#define UI_HWFORM_H

#include <QtCore/QVariant>
#include <QtGui/QAction>
#include <QtGui/QApplication>
#include <QtGui/QButtonGroup>
#include <QtGui/QCheckBox>
#include <QtGui/QComboBox>
#include <QtGui/QGroupBox>
#include <QtGui/QLabel>
#include <QtGui/QLineEdit>
#include <QtGui/QListWidget>
#include <QtGui/QMainWindow>
#include <QtGui/QPushButton>
#include <QtGui/QStackedWidget>
#include <QtGui/QToolBox>
#include <QtGui/QWidget>
#include <QStackedLayout>

class PageMain;
class PageLocalGame;
class PageEditTeam;
class PageMultiplayer;
class PagePlayDemo;
class PageOptions;
class PageNet;
class PageNetChat;
class PageNetGame;

class Ui_HWForm
{
public:
	QWidget *centralWidget;

	PageMain *pageMain;
	PageLocalGame *pageLocalGame;
	PageEditTeam *pageEditTeam;
	PageMultiplayer *pageMultiplayer;
	PagePlayDemo *pagePlayDemo;
	PageOptions *pageOptions;
	PageNet *pageNet;
	PageNetChat *pageNetChat;
	PageNetGame *pageNetGame;

	QStackedLayout *Pages;
	QFont *font14;

	void setupUi(QMainWindow *HWForm);
	void SetupFonts();
	void SetupPages(QWidget *Parent);
	void SetupPageNetChat(QWidget *Parent);
	void SetupPageNetGame(QWidget *Parent);
};

#endif // UI_HWFORM_H
