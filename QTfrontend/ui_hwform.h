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
#include "teamselect.h"
#include "gamecfgwidget.h"

class Ui_HWForm
{
public:
	QWidget *centralWidget;
	QWidget *pageLG;
	QPushButton *BtnSimpleGame;
	QPushButton *BtnSPBack;
	QWidget *pageET;
	QGroupBox *GBoxHedgehogs;
	QGroupBox *GBoxTeam;
	QGroupBox *GBoxFort;
	QComboBox *CBFort;
	QLabel *FortPreview;
	QGroupBox *GBoxGrave;
	QComboBox *CBGrave;
	QLabel *GravePreview;
	QGroupBox *GBoxBinds;
	QToolBox *BindsBox;
	QWidget *page_A;
	QWidget *page_W;
	QWidget *page_WP;
	QWidget *page_O;
	QPushButton *BtnTeamDiscard;
	QPushButton *BtnTeamSave;
	QWidget *pageOpt;
	QGroupBox *groupBox;
	QPushButton *BtnNewTeam;
	QPushButton *BtnEditTeam;
	QComboBox *CBTeamName;
	QComboBox *CBResolution;
	QCheckBox *CBEnableSound;
	QCheckBox *CBFullscreen;
	QLabel *label;
	QLineEdit *editNetNick;
	QPushButton *BtnSaveOptions;
	QPushButton *BtnSetupBack;
	QWidget *pageMP;
	QPushButton *BtnMPBack;
	QListWidget *listWidget;
	QWidget *pagePDemo;
	QPushButton *BtnPlayDemo;
	QListWidget *DemosList;
	QPushButton *BtnDemosBack;
	QWidget *pageNet;
	QPushButton *BtnNetConnect;
	QPushButton *BtnNetBack;
	QWidget *pageNetChat;
	QPushButton *BtnNetChatDisconnect;
	QListWidget *ChannelsList;
	QPushButton *BtnNetChatJoin;
	QPushButton *BtnNetChatCreate;
	QWidget *pageNetGame;
	QPushButton *BtnNetCFGBack;
	QPushButton *BtnNetCFGAddTeam;
	QPushButton *BtnNetCFGGo;
	QListWidget *listNetTeams;
	QWidget *pageMain;
	QPushButton *BtnSinglePlayer;
	QPushButton *BtnMultiplayer;
	QPushButton *BtnSetup;
	QPushButton *BtnExit;
	QPushButton *BtnDemos;
	QPushButton *BtnNet;

	QStackedLayout *Pages;
	QFont *font14;
	TeamSelWidget *PageLGTeamsSelect;
	GameCFGWidget *pageLGGameCFG;

	void setupUi(QMainWindow *HWForm);
	void SetupFonts();
	void SetupPages(QWidget *Parent);
	void SetupPageLocalGame(QWidget *Parent);
	void SetupPageEditTeam(QWidget *Parent);
	void SetupPageOptions(QWidget *Parent);
	void SetupPageMultiplayer(QWidget *Parent);
	void SetupPagePlayDemo(QWidget *Parent);
	void SetupPageNet(QWidget *Parent);
	void SetupPageNetChat(QWidget *Parent);
	void SetupPageNetGame(QWidget *Parent);
	void SetupPageMain(QWidget *Parent);

	void retranslateUi(QMainWindow *HWForm);
};

namespace Ui {
	class HWForm: public Ui_HWForm {};
} // namespace Ui

#endif // UI_HWFORM_H
