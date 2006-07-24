#include "ui_hwform.h"
#include <QVBoxLayout>
#include <QGridLayout>

void Ui_HWForm::setupUi(QMainWindow *HWForm)
{
	SetupFonts();

	HWForm->setObjectName(QString::fromUtf8("HWForm"));
	HWForm->resize(QSize(640, 450).expandedTo(HWForm->minimumSizeHint()));
	HWForm->setMinimumSize(QSize(620, 430));

	centralWidget = new QWidget(HWForm);
	centralWidget->setObjectName(QString::fromUtf8("centralWidget"));

	SetupPages(centralWidget);

	HWForm->setCentralWidget(centralWidget);
	retranslateUi(HWForm);
	QObject::connect(BtnExit, SIGNAL(clicked()), HWForm, SLOT(close()));

	Pages->setCurrentIndex(0);
	CBFort->setCurrentIndex(-1);
	CBGrave->setCurrentIndex(-1);
	BindsBox->setCurrentIndex(0);


	QMetaObject::connectSlotsByName(HWForm);
}

void Ui_HWForm::SetupFonts()
{
	font14 = new QFont();
	font14->setFamily(QString::fromUtf8("MS Shell Dlg"));
	font14->setPointSize(14);
	font14->setBold(false);
	font14->setItalic(false);
	font14->setUnderline(false);
	font14->setWeight(50);
	font14->setStrikeOut(false);
}

void Ui_HWForm::SetupPages(QWidget *Parent)
{
	Pages =	new QStackedLayout(Parent);

	pageLG = new QWidget();
	SetupPageLocalGame(pageLG);
	Pages->addWidget(pageLG);

	pageET = new QWidget();
	SetupPageEditTeam(pageET);
	Pages->addWidget(pageET);

	pageOpt = new QWidget();
	SetupPageOptions(pageOpt);
	Pages->addWidget(pageOpt);

	pageMP = new QWidget();
	SetupPageMultiplayer(pageMP);
	Pages->addWidget(pageMP);

	pagePDemo =	new QWidget();
	SetupPagePlayDemo(pagePDemo);
	Pages->addWidget(pagePDemo);

	pageNet = new QWidget();
	SetupPageNet(pageNet);
	Pages->addWidget(pageNet);

	pageNetChat	= new QWidget();
	SetupPageNetChat(pageNetChat);
	Pages->addWidget(pageNetChat);

	pageNetGame	= new QWidget();
	SetupPageNetGame(pageNetGame);
	Pages->addWidget(pageNetGame);

	pageMain = new QWidget();
	SetupPageMain(pageMain);
	Pages->addWidget(pageMain);
}

void Ui_HWForm::SetupPageLocalGame(QWidget *Parent)
{
	BtnSimpleGame = new	QPushButton(Parent);
	BtnSimpleGame->setGeometry(QRect(330, 380, 161, 41));
	BtnSimpleGame->setFont(*font14);
	BtnSimpleGame->setCheckable(false);
	BtnSimpleGame->setChecked(false);
	BtnSPBack =	new QPushButton(Parent);
	BtnSPBack->setGeometry(QRect(120, 380, 161,	41));
	BtnSPBack->setFont(*font14);
	BtnSPBack->setCheckable(false);
	BtnSPBack->setChecked(false);

}

void Ui_HWForm::SetupPageEditTeam(QWidget *Parent)
{
	GBoxHedgehogs = new	QGroupBox(Parent);
	GBoxHedgehogs->setGeometry(QRect(20, 70, 161, 261));
	GBoxTeam = new QGroupBox(Parent);
	GBoxTeam->setGeometry(QRect(20, 10,	161, 51));
	GBoxFort = new QGroupBox(Parent);
	GBoxFort->setGeometry(QRect(420, 110, 181, 221));
	CBFort = new QComboBox(GBoxFort);
	CBFort->setGeometry(QRect(10, 20, 161, 21));
	CBFort->setMaxCount(65535);
	FortPreview	= new QLabel(GBoxFort);
	FortPreview->setGeometry(QRect(10, 50, 161,	161));
	FortPreview->setPixmap(QPixmap());
	FortPreview->setScaledContents(true);
	GBoxGrave =	new QGroupBox(Parent);
	GBoxGrave->setGeometry(QRect(420, 10, 181, 91));
	CBGrave = new QComboBox(GBoxGrave);
	CBGrave->setGeometry(QRect(10, 20, 161, 21));
	CBGrave->setMaxCount(65535);
	GravePreview = new QLabel(GBoxGrave);
	GravePreview->setGeometry(QRect(80,	50, 32,	32));
	GravePreview->setScaledContents(true);
	GBoxBinds =	new QGroupBox(Parent);
	GBoxBinds->setGeometry(QRect(200, 10, 201, 431));
	BindsBox = new QToolBox(GBoxBinds);
	BindsBox->setGeometry(QRect(10, 20,	181, 401));
	BindsBox->setLineWidth(0);
	page_A = new QWidget();
	page_A->setGeometry(QRect(0, 0, 96,	26));
	BindsBox->addItem(page_A, QApplication::translate("HWForm",	"Actions", 0, QApplication::UnicodeUTF8));
	page_W = new QWidget();
	page_W->setObjectName(QString::fromUtf8("page_W"));
	BindsBox->addItem(page_W, QApplication::translate("HWForm",	"Weapons", 0, QApplication::UnicodeUTF8));
	page_WP = new QWidget();
	page_WP->setObjectName(QString::fromUtf8("page_WP"));
	BindsBox->addItem(page_WP, QApplication::translate("HWForm", "Weapon properties", 0, QApplication::UnicodeUTF8));
	page_O = new QWidget();
	page_O->setObjectName(QString::fromUtf8("page_O"));
	page_O->setGeometry(QRect(0, 0, 96,	26));
	BindsBox->addItem(page_O, QApplication::translate("HWForm",	"Other", 0, QApplication::UnicodeUTF8));
	BtnTeamDiscard = new QPushButton(pageET);
	BtnTeamDiscard->setGeometry(QRect(440, 380,	161, 41));
	BtnTeamDiscard->setFont(*font14);
	BtnTeamDiscard->setCheckable(false);
	BtnTeamDiscard->setChecked(false);
	BtnTeamSave	= new QPushButton(Parent);
	BtnTeamSave->setGeometry(QRect(20, 380, 161, 41));
	BtnTeamSave->setFont(*font14);
	BtnTeamSave->setCheckable(false);
	BtnTeamSave->setChecked(false);
}

void Ui_HWForm::SetupPageOptions(QWidget *Parent)
{
	groupBox = new QGroupBox(Parent);
	groupBox->setGeometry(QRect(20, 10,	591, 71));
	BtnNewTeam = new QPushButton(groupBox);
	BtnNewTeam->setGeometry(QRect(10, 20, 160, 40));
	BtnNewTeam->setFont(*font14);
	BtnEditTeam	= new QPushButton(groupBox);
	BtnEditTeam->setGeometry(QRect(400,	20, 160, 40));
	BtnEditTeam->setFont(*font14);
	CBTeamName = new QComboBox(groupBox);
	CBTeamName->setGeometry(QRect(200, 30, 171,	22));
	CBResolution = new QComboBox(Parent);
	CBResolution->setGeometry(QRect(20,	120, 151, 22));
	CBEnableSound = new	QCheckBox(Parent);
	CBEnableSound->setGeometry(QRect(20, 180, 101, 18));
	CBFullscreen = new QCheckBox(Parent);
	CBFullscreen->setGeometry(QRect(20,	160, 101, 18));
	label = new	QLabel(Parent);
	label->setGeometry(QRect(10, 233, 47, 13));
	editNetNick	= new QLineEdit(Parent);
	editNetNick->setGeometry(QRect(60, 230, 113, 20));
	editNetNick->setMaxLength(30);
	BtnSaveOptions = new QPushButton(Parent);
	BtnSaveOptions->setGeometry(QRect(20, 380, 161, 41));
	BtnSaveOptions->setFont(*font14);
	BtnSaveOptions->setCheckable(false);
	BtnSaveOptions->setChecked(false);
	BtnSetupBack = new QPushButton(Parent);
	BtnSetupBack->setGeometry(QRect(440, 380, 161, 41));
	BtnSetupBack->setFont(*font14);
	BtnSetupBack->setCheckable(false);
	BtnSetupBack->setChecked(false);
}

void Ui_HWForm::SetupPageMultiplayer(QWidget *Parent)
{
	BtnMPBack = new	QPushButton(Parent);
	BtnMPBack->setGeometry(QRect(240, 340, 161, 41));
	BtnMPBack->setFont(*font14);
	BtnMPBack->setCheckable(false);
	BtnMPBack->setChecked(false);
	listWidget = new QListWidget(Parent);
	listWidget->setGeometry(QRect(160, 50, 221, 211));
	listWidget->setModelColumn(0);
}

void Ui_HWForm::SetupPagePlayDemo(QWidget *Parent)
{
	BtnPlayDemo	= new QPushButton(Parent);
	BtnPlayDemo->setGeometry(QRect(240,	330, 161, 41));
	BtnPlayDemo->setFont(*font14);
	BtnPlayDemo->setCheckable(false);
	BtnPlayDemo->setChecked(false);
	DemosList =	new QListWidget(Parent);
	DemosList->setGeometry(QRect(170, 10, 311, 311));
	BtnDemosBack = new QPushButton(Parent);
	BtnDemosBack->setGeometry(QRect(240, 380, 161, 41));
	BtnDemosBack->setFont(*font14);
	BtnDemosBack->setCheckable(false);
	BtnDemosBack->setChecked(false);
}

void Ui_HWForm::SetupPageNet(QWidget *Parent)
{
	BtnNetConnect = new	QPushButton(Parent);
	BtnNetConnect->setGeometry(QRect(250, 140, 161, 41));
	BtnNetConnect->setFont(*font14);
	BtnNetConnect->setCheckable(false);
	BtnNetConnect->setChecked(false);
	BtnNetBack = new QPushButton(Parent);
	BtnNetBack->setGeometry(QRect(250, 390, 161, 41));
	BtnNetBack->setFont(*font14);
	BtnNetBack->setCheckable(false);
	BtnNetBack->setChecked(false);
}

void Ui_HWForm::SetupPageNetChat(QWidget *Parent)
{
	BtnNetChatDisconnect = new QPushButton(Parent);
	BtnNetChatDisconnect->setGeometry(QRect(460, 390, 161, 41));
	BtnNetChatDisconnect->setFont(*font14);
	BtnNetChatDisconnect->setCheckable(false);
	BtnNetChatDisconnect->setChecked(false);
	ChannelsList = new QListWidget(Parent);
	ChannelsList->setGeometry(QRect(20,	10, 201, 331));
	BtnNetChatJoin = new QPushButton(Parent);
	BtnNetChatJoin->setGeometry(QRect(460, 290,	161, 41));
	BtnNetChatJoin->setFont(*font14);
	BtnNetChatJoin->setCheckable(false);
	BtnNetChatJoin->setChecked(false);
	BtnNetChatCreate = new QPushButton(Parent);
	BtnNetChatCreate->setGeometry(QRect(460, 340, 161, 41));
	BtnNetChatCreate->setFont(*font14);
	BtnNetChatCreate->setCheckable(false);
	BtnNetChatCreate->setChecked(false);
}

void Ui_HWForm::SetupPageNetGame(QWidget *Parent)
{
	BtnNetCFGBack = new	QPushButton(Parent);
	BtnNetCFGBack->setGeometry(QRect(260, 390, 161, 41));
	BtnNetCFGBack->setFont(*font14);
	BtnNetCFGBack->setCheckable(false);
	BtnNetCFGBack->setChecked(false);
	BtnNetCFGAddTeam = new QPushButton(Parent);
	BtnNetCFGAddTeam->setGeometry(QRect(260, 290, 161, 41));
	BtnNetCFGAddTeam->setFont(*font14);
	BtnNetCFGAddTeam->setCheckable(false);
	BtnNetCFGAddTeam->setChecked(false);
	BtnNetCFGGo	= new QPushButton(Parent);
	BtnNetCFGGo->setGeometry(QRect(260,	340, 161, 41));
	BtnNetCFGGo->setFont(*font14);
	BtnNetCFGGo->setCheckable(false);
	BtnNetCFGGo->setChecked(false);
	listNetTeams = new QListWidget(Parent);
	listNetTeams->setGeometry(QRect(270, 30, 120, 80));
}

void Ui_HWForm::SetupPageMain(QWidget *Parent)
{
	QGridLayout * PageMainLayout = new QGridLayout(Parent);
	PageMainLayout->setMargin(15);
	BtnSinglePlayer = new QPushButton(Parent);
	BtnSinglePlayer->setFont(*font14);
	PageMainLayout->addWidget(BtnSinglePlayer, 0, 0);
	BtnMultiplayer = new QPushButton(Parent);
	BtnMultiplayer->setFont(*font14);
	PageMainLayout->addWidget(BtnMultiplayer, 0, 1);
	BtnNet = new QPushButton(Parent);
	BtnNet->setFont(*font14);
	PageMainLayout->addWidget(BtnNet, 1, 0);
	BtnSetup = new QPushButton(Parent);
	BtnSetup->setFont(*font14);
	PageMainLayout->addWidget(BtnSetup, 1, 1);
	BtnDemos = new QPushButton(Parent);
	BtnDemos->setFont(*font14);
	PageMainLayout->addWidget(BtnDemos, 2, 0);
	BtnExit = new QPushButton(Parent);
	BtnExit->setFont(*font14);
	PageMainLayout->addWidget(BtnExit, 2, 1);
}

void Ui_HWForm::retranslateUi(QMainWindow *HWForm)
{
	HWForm->setWindowTitle(QApplication::translate("HWForm", "-= by unC0Rr =-",	0, QApplication::UnicodeUTF8));
	BtnSimpleGame->setText(QApplication::translate("HWForm", "Simple Game", 0, QApplication::UnicodeUTF8));
	BtnSPBack->setText(QApplication::translate("HWForm", "Back", 0, QApplication::UnicodeUTF8));
	GBoxHedgehogs->setTitle(QApplication::translate("HWForm", "Team Members", 0, QApplication::UnicodeUTF8));
	GBoxTeam->setTitle(QApplication::translate("HWForm", "Team", 0, QApplication::UnicodeUTF8));
	GBoxFort->setTitle(QApplication::translate("HWForm", "Fort", 0, QApplication::UnicodeUTF8));
	FortPreview->setText(QApplication::translate("HWForm", "", 0, QApplication::UnicodeUTF8));
	GBoxGrave->setTitle(QApplication::translate("HWForm", "Grave", 0, QApplication::UnicodeUTF8));
	GravePreview->setText(QApplication::translate("HWForm", "",	0, QApplication::UnicodeUTF8));
	GBoxBinds->setTitle(QApplication::translate("HWForm", "Key binds", 0, QApplication::UnicodeUTF8));
	BindsBox->setItemText(BindsBox->indexOf(page_A), QApplication::translate("HWForm", "Actions", 0, QApplication::UnicodeUTF8));
	BindsBox->setItemText(BindsBox->indexOf(page_W), QApplication::translate("HWForm", "Weapons", 0, QApplication::UnicodeUTF8));
	BindsBox->setItemText(BindsBox->indexOf(page_WP), QApplication::translate("HWForm",	"Weapon	properties", 0,	QApplication::UnicodeUTF8));
	BindsBox->setItemText(BindsBox->indexOf(page_O), QApplication::translate("HWForm", "Other",	0, QApplication::UnicodeUTF8));
	BtnTeamDiscard->setText(QApplication::translate("HWForm", "Discard", 0, QApplication::UnicodeUTF8));
	BtnTeamSave->setText(QApplication::translate("HWForm", "Save", 0, QApplication::UnicodeUTF8));
	groupBox->setTitle(QApplication::translate("HWForm", "Teams", 0, QApplication::UnicodeUTF8));
	BtnNewTeam->setText(QApplication::translate("HWForm", "New team", 0, QApplication::UnicodeUTF8));
	BtnEditTeam->setText(QApplication::translate("HWForm", "Edit team",	0, QApplication::UnicodeUTF8));
	CBResolution->addItem(QApplication::translate("HWForm", "640x480", 0, QApplication::UnicodeUTF8));
	CBResolution->addItem(QApplication::translate("HWForm", "800x600", 0, QApplication::UnicodeUTF8));
	CBResolution->addItem(QApplication::translate("HWForm", "1024x768",	0, QApplication::UnicodeUTF8));
	CBResolution->addItem(QApplication::translate("HWForm", "1280x1024", 0, QApplication::UnicodeUTF8));
	CBEnableSound->setText(QApplication::translate("HWForm", "Enable sound", 0,	QApplication::UnicodeUTF8));
	CBFullscreen->setText(QApplication::translate("HWForm", "Fullscreen", 0, QApplication::UnicodeUTF8));
	label->setText(QApplication::translate("HWForm", "Net nick", 0, QApplication::UnicodeUTF8));
	editNetNick->setText(QApplication::translate("HWForm", "unnamed", 0, QApplication::UnicodeUTF8));
	BtnSaveOptions->setText(QApplication::translate("HWForm", "Save", 0, QApplication::UnicodeUTF8));
	BtnSetupBack->setText(QApplication::translate("HWForm", "Back", 0, QApplication::UnicodeUTF8));
	BtnMPBack->setText(QApplication::translate("HWForm", "Back", 0, QApplication::UnicodeUTF8));
	BtnPlayDemo->setText(QApplication::translate("HWForm", "Play demo",	0, QApplication::UnicodeUTF8));
	BtnDemosBack->setText(QApplication::translate("HWForm", "Back", 0, QApplication::UnicodeUTF8));
	BtnNetConnect->setText(QApplication::translate("HWForm", "Connect",	0, QApplication::UnicodeUTF8));
	BtnNetBack->setText(QApplication::translate("HWForm", "Back", 0, QApplication::UnicodeUTF8));
	BtnNetChatDisconnect->setText(QApplication::translate("HWForm", "Disconnect", 0, QApplication::UnicodeUTF8));
	BtnNetChatJoin->setText(QApplication::translate("HWForm", "Join", 0, QApplication::UnicodeUTF8));
	BtnNetChatCreate->setText(QApplication::translate("HWForm",	"Create", 0, QApplication::UnicodeUTF8));
	BtnNetCFGBack->setText(QApplication::translate("HWForm", "Back", 0,	QApplication::UnicodeUTF8));
	BtnNetCFGAddTeam->setText(QApplication::translate("HWForm",	"Add Team", 0, QApplication::UnicodeUTF8));
	BtnNetCFGGo->setText(QApplication::translate("HWForm", "Go!", 0, QApplication::UnicodeUTF8));
	BtnSinglePlayer->setText(QApplication::translate("HWForm", "Single Player",	0, QApplication::UnicodeUTF8));
	BtnMultiplayer->setText(QApplication::translate("HWForm", "Multiplayer", 0,	QApplication::UnicodeUTF8));
	BtnSetup->setText(QApplication::translate("HWForm",	"Setup", 0, QApplication::UnicodeUTF8));
	BtnExit->setText(QApplication::translate("HWForm", "Exit", 0, QApplication::UnicodeUTF8));
	BtnDemos->setText(QApplication::translate("HWForm",	"Demos", 0, QApplication::UnicodeUTF8));
	BtnNet->setText(QApplication::translate("HWForm", "Net game", 0, QApplication::UnicodeUTF8));
	Q_UNUSED(HWForm);
}
