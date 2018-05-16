/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include <QGridLayout>
#include <QHBoxLayout>
#include <QPushButton>
#include <QGroupBox>
#include <QComboBox>
#include <QCheckBox>
#include <QLabel>
#include <QTableWidget>
#include <QLineEdit>
#include <QSpinBox>
#include <QTextBrowser>
#include <QScrollArea>
#include <QHeaderView>
#include <QSlider>
#include <QSignalMapper>
#include <QColorDialog>
#include <QMessageBox>
#include <QStandardItemModel>
#include <QDebug>

#include "pageoptions.h"
#include "gameuiconfig.h"
#include "hwconsts.h"
#include "fpsedit.h"
#include "DataManager.h"
#include "LibavInteraction.h"
#include "AutoUpdater.h"
#include "HWApplication.h"
#include "keybinder.h"

#ifdef __APPLE__
#ifdef SPARKLE_ENABLED
#include "SparkleAutoUpdater.h"
#endif
#endif

const int OPTION_BOX_SPACING = 10;

OptionGroupBox::OptionGroupBox(const QString & iconName,
                               const QString & title,
                               QWidget * parent) : IconedGroupBox(parent)
{
    setIcon(QIcon(iconName));
    setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
    setTitle(title);
    setMinimumWidth(300);
    m_layout = new QGridLayout(this);
    m_layout->setColumnStretch(0, 0);
    m_layout->setColumnStretch(1, 1);
}

QGridLayout * OptionGroupBox::layout()
{
    return m_layout;
}

void OptionGroupBox::addDivider()
{
    QFrame * hr = new QFrame(this);
    hr->setFrameStyle(QFrame::HLine);
    hr->setLineWidth(3);
    hr->setFixedHeight(10);
    m_layout->addWidget(hr, m_layout->rowCount(), 0, 1, m_layout->columnCount());
}

// TODO cleanup
QLayout * PageOptions::bodyLayoutDefinition()
{
    QVBoxLayout * pageLayout = new QVBoxLayout();

    QTabWidget * tabs = new QTabWidget(this);
    pageLayout->addWidget(tabs);

    binder = new KeyBinder(this, tr("Select an action to change what key controls it"), tr("Reset to default"), tr("Reset all binds"));
    connect(binder, SIGNAL(bindUpdate(int)), this, SLOT(bindUpdated(int)));
    connect(binder, SIGNAL(resetAllBinds()), this, SLOT(resetAllBinds()));

    QWidget * pageGame = new QWidget(this);
    tabs->addTab(pageGame, tr("Game"));

    QWidget * pageGraphics = new QWidget(this);
    tabs->addTab(pageGraphics, tr("Graphics"));

    QWidget * pageAudio = new QWidget(this);
    tabs->addTab(pageAudio, tr("Audio"));

    binderTab = tabs->addTab(binder, tr("Controls"));

#ifdef VIDEOREC
    QWidget * pageVideoRec = new QWidget(this);
    tabs->addTab(pageVideoRec, tr("Video Recording"));
#endif

    QWidget * pageNetwork = new QWidget(this);
    tabs->addTab(pageNetwork, tr("Network"));

    QWidget * pageAdvanced = new QWidget(this);
    tabs->addTab(pageAdvanced, tr("Advanced"));

    connect(tabs, SIGNAL(currentChanged(int)), this, SLOT(tabIndexChanged(int)));

    QPixmap pmNew(":/res/new.png");
    QPixmap pmEdit(":/res/edit.png");
    QPixmap pmDelete(":/res/delete.png");

    { // game page
        QVBoxLayout * leftColumn, * rightColumn;
        setupTabPage(pageGame, &leftColumn, &rightColumn);

        { // group: Teams
            OptionGroupBox * groupTeams = new OptionGroupBox(":/res/teamicon.png", tr("Teams"), this);
            groupTeams->setMinimumWidth(400);
            rightColumn->addWidget(groupTeams);

            groupTeams->layout()->setColumnStretch(0, 1);

            CBTeamName = new QComboBox(groupTeams);
            CBTeamName->setMaxVisibleItems(50);
            CBTeamName->setSizePolicy(QSizePolicy::Preferred, QSizePolicy::Expanding);
            groupTeams->layout()->addWidget(CBTeamName, 0, 0);

            BtnNewTeam = new QPushButton(groupTeams);
            BtnNewTeam->setWhatsThis(tr("New team"));
            BtnNewTeam->setIconSize(pmNew.size());
            BtnNewTeam->setIcon(pmNew);
            BtnNewTeam->setMaximumWidth(pmNew.width() + 6);
            connect(BtnNewTeam, SIGNAL(clicked()), this, SIGNAL(newTeamRequested()));
            groupTeams->layout()->addWidget(BtnNewTeam, 0, 1);

            BtnEditTeam = new QPushButton(groupTeams);
            BtnEditTeam->setWhatsThis(tr("Edit team"));
            BtnEditTeam->setIconSize(pmEdit.size());
            BtnEditTeam->setIcon(pmEdit);
            BtnEditTeam->setMaximumWidth(pmEdit.width() + 6);
            connect(BtnEditTeam, SIGNAL(clicked()), this, SLOT(requestEditSelectedTeam()));
            groupTeams->layout()->addWidget(BtnEditTeam, 0, 2);

            BtnDeleteTeam = new QPushButton(groupTeams);
            BtnDeleteTeam->setWhatsThis(tr("Delete team"));
            BtnDeleteTeam->setIconSize(pmDelete.size());
            BtnDeleteTeam->setIcon(pmDelete);
            BtnDeleteTeam->setMaximumWidth(pmDelete.width() + 6);
            connect(BtnDeleteTeam, SIGNAL(clicked()), this, SLOT(requestDeleteSelectedTeam()));
            groupTeams->layout()->addWidget(BtnDeleteTeam, 0, 3);

            LblNoEditTeam = new QLabel(groupTeams);
            LblNoEditTeam->setText(tr("You can't edit teams from team selection. Go back to main menu to add, edit or delete teams."));
            LblNoEditTeam->setWordWrap(true);
            LblNoEditTeam->setVisible(false);
            groupTeams->layout()->addWidget(LblNoEditTeam, 1, 0, 1, 4);
        }

        { // group: schemes
            OptionGroupBox * groupSchemes = new OptionGroupBox(":/res/schemeicon.png", tr("Schemes"), this);
            leftColumn->addWidget(groupSchemes);

            groupSchemes->layout()->setColumnStretch(0, 1);

            SchemesName = new QComboBox(groupSchemes);
            SchemesName->setMaxVisibleItems(50);
            SchemesName->setSizePolicy(QSizePolicy::Preferred, QSizePolicy::Expanding);
            groupSchemes->layout()->addWidget(SchemesName, 0, 0);

            SchemeNew = new QPushButton(groupSchemes);
            SchemeNew->setWhatsThis(tr("New scheme"));
            SchemeNew->setIconSize(pmNew.size());
            SchemeNew->setIcon(pmNew);
            SchemeNew->setMaximumWidth(pmNew.width() + 6);
            groupSchemes->layout()->addWidget(SchemeNew, 0, 1);

            SchemeEdit = new QPushButton(groupSchemes);
            SchemeEdit->setWhatsThis(tr("Edit scheme"));
            SchemeEdit->setIconSize(pmEdit.size());
            SchemeEdit->setIcon(pmEdit);
            SchemeEdit->setMaximumWidth(pmEdit.width() + 6);
            groupSchemes->layout()->addWidget(SchemeEdit, 0, 2);

            SchemeDelete = new QPushButton(groupSchemes);
            SchemeDelete->setWhatsThis(tr("Delete scheme"));
            SchemeDelete->setIconSize(pmDelete.size());
            SchemeDelete->setIcon(pmDelete);
            SchemeDelete->setMaximumWidth(pmDelete.width() + 6);
            groupSchemes->layout()->addWidget(SchemeDelete, 0, 3);
        }

        { // group: weapons
            OptionGroupBox * groupWeapons = new OptionGroupBox(":/res/weaponsicon.png", tr("Weapons"), this);
            leftColumn->addWidget(groupWeapons);

            groupWeapons->layout()->setColumnStretch(0, 1);

            WeaponsName = new QComboBox(groupWeapons);
            WeaponsName->setMaxVisibleItems(50);
            WeaponsName->setSizePolicy(QSizePolicy::Preferred, QSizePolicy::Expanding);
            groupWeapons->layout()->addWidget(WeaponsName, 0, 0);

            WeaponNew = new QPushButton(groupWeapons);
            WeaponNew->setWhatsThis(tr("New weapon set"));
            WeaponNew->setIconSize(pmNew.size());
            WeaponNew->setIcon(pmNew);
            WeaponNew->setMaximumWidth(pmNew.width() + 6);
            groupWeapons->layout()->addWidget(WeaponNew, 0, 1);

            WeaponEdit = new QPushButton(groupWeapons);
            WeaponEdit->setWhatsThis(tr("Edit weapon set"));
            WeaponEdit->setIconSize(pmEdit.size());
            WeaponEdit->setIcon(pmEdit);
            WeaponEdit->setMaximumWidth(pmEdit.width() + 6);
            groupWeapons->layout()->addWidget(WeaponEdit, 0, 2);

            WeaponDelete = new QPushButton(groupWeapons);
            WeaponDelete->setWhatsThis(tr("Delete weapon set"));
            WeaponDelete->setIconSize(pmDelete.size());
            WeaponDelete->setIcon(pmDelete);
            WeaponDelete->setMaximumWidth(pmDelete.width() + 6);
            groupWeapons->layout()->addWidget(WeaponDelete, 0, 3);
        }

        leftColumn->addStretch(1);
        rightColumn->addStretch(1);
    }

    { // graphics page
        QVBoxLayout * leftColumn, * rightColumn;
        setupTabPage(pageGraphics, &leftColumn, &rightColumn);

        { // group: game
            OptionGroupBox * groupGame = new OptionGroupBox(":/res/graphicsicon.png", tr("Game"), this);
            leftColumn->addWidget(groupGame);

            groupGame->layout()->setColumnStretch(0, 0);
            groupGame->layout()->setColumnStretch(1, 0);
            groupGame->layout()->setColumnStretch(2, 1);

            // Fullscreen

            CBFullscreen = new QCheckBox(groupGame);
            groupGame->layout()->addWidget(CBFullscreen, 0, 0, 1, 2);
            CBFullscreen->setText(QLabel::tr("Fullscreen"));

            // Fullscreen resolution

            lblFullScreenRes = new QLabel(groupGame);
            lblFullScreenRes->setText(QLabel::tr("Fullscreen Resolution"));
            groupGame->layout()->addWidget(lblFullScreenRes, 1, 0);

            CBResolution = new QComboBox(groupGame);
            CBResolution->setMaxVisibleItems(50);
            CBResolution->setFixedWidth(200);
            groupGame->layout()->addWidget(CBResolution, 1, 1, Qt::AlignLeft);

            // Windowed resolution

            lblWinScreenRes = new QLabel(groupGame);
            lblWinScreenRes->setText(QLabel::tr("Windowed Resolution"));
            groupGame->layout()->addWidget(lblWinScreenRes, 2, 0);

            winResContainer = new QWidget();
            QHBoxLayout * winResLayout = new QHBoxLayout(winResContainer);
            winResLayout->setSpacing(0);
            groupGame->layout()->addWidget(winResContainer, 2, 1);

            QLabel *winLabelX = new QLabel(groupGame);
            //: Multiplication sign, to be used between two numbers. Note the “x” is only a dummy character, we recommend to use “×” if your language permits it
            winLabelX->setText(tr("x"));
            winLabelX->setFixedWidth(40);
            winLabelX->setAlignment(Qt::AlignCenter);

            // TODO: less random max. also:
            // make some min/max-consts, shared with engine?
            windowWidthEdit = new QSpinBox(groupGame);
            windowWidthEdit->setRange(640, 102400);
            windowWidthEdit->setFixedSize(60, CBResolution->height());
            windowHeightEdit = new QSpinBox(groupGame);
            windowHeightEdit->setRange(480, 102400);
            windowHeightEdit->setFixedSize(60, CBResolution->height());

            winResLayout->addWidget(windowWidthEdit, 0);
            winResLayout->addWidget(winLabelX, 0);
            winResLayout->addWidget(windowHeightEdit, 0);
            winResLayout->addStretch(1);

            // Quality

            QLabel * lblQuality = new QLabel(groupGame);
            lblQuality->setText(QLabel::tr("Quality"));
            lblQuality->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
            groupGame->layout()->addWidget(lblQuality, 3, 0);

            SLQuality = new QSlider(Qt::Horizontal, groupGame);
            SLQuality->setTickPosition(QSlider::TicksBelow);
            SLQuality->setMaximum(5);
            SLQuality->setMinimum(0);
            SLQuality->setFixedWidth(150);
            groupGame->layout()->addWidget(SLQuality, 3, 1, Qt::AlignLeft);

            // Stereo spacing

            QLabel * lblStereo = new QLabel(groupGame);
            lblStereo->setText(QLabel::tr("Stereoscopy"));
            groupGame->layout()->addWidget(lblStereo, 4, 0);

            CBStereoMode = new QComboBox(groupGame);
            CBStereoMode->setWhatsThis(QComboBox::tr("Stereoscopy creates an illusion of depth when you wear 3D glasses."));
            CBStereoMode->setMaxVisibleItems(50);
            CBStereoMode->addItem(QComboBox::tr("Disabled"));
            CBStereoMode->addItem(QComboBox::tr("Red/Cyan"));
            CBStereoMode->addItem(QComboBox::tr("Cyan/Red"));
            CBStereoMode->addItem(QComboBox::tr("Red/Blue"));
            CBStereoMode->addItem(QComboBox::tr("Blue/Red"));
            CBStereoMode->addItem(QComboBox::tr("Red/Green"));
            CBStereoMode->addItem(QComboBox::tr("Green/Red"));
            CBStereoMode->addItem(QComboBox::tr("Red/Cyan grayscale"));
            CBStereoMode->addItem(QComboBox::tr("Cyan/Red grayscale"));
            CBStereoMode->addItem(QComboBox::tr("Red/Blue grayscale"));
            CBStereoMode->addItem(QComboBox::tr("Blue/Red grayscale"));
            CBStereoMode->addItem(QComboBox::tr("Red/Green grayscale"));
            CBStereoMode->addItem(QComboBox::tr("Green/Red grayscale"));
            CBStereoMode->addItem(QComboBox::tr("Side-by-side"));
            CBStereoMode->addItem(QComboBox::tr("Top-Bottom"));
            CBStereoMode->setFixedWidth(CBResolution->width());
            groupGame->layout()->addWidget(CBStereoMode, 4, 1);

            // Divider

            groupGame->addDivider(); // row 5

            // FPS limit

            QHBoxLayout * fpsLayout = new QHBoxLayout();
            groupGame->layout()->addLayout(fpsLayout, 6, 0, 1, 2);
            QLabel * maxfps = new QLabel(groupGame);
            maxfps->setText(QLabel::tr("FPS limit"));
            fpsLayout->addWidget(maxfps);
            fpsLayout->addSpacing(30);
            fpsedit = new FPSEdit(groupGame);
            fpsLayout->addWidget(fpsedit);

            // Show FPS

            CBShowFPS = new QCheckBox(groupGame);
            CBShowFPS->setText(QCheckBox::tr("Show FPS"));
            fpsLayout->addWidget(CBShowFPS);
            fpsLayout->addStretch(1);

            // Divider

            groupGame->addDivider(); // row 7

            // Alternative damage show

            CBAltDamage = new QCheckBox(groupGame);
            CBAltDamage->setText(QCheckBox::tr("Alternative damage show"));
            groupGame->layout()->addWidget(CBAltDamage, 8, 0, 1, 2);

            // Show ammo menu tooltips

            WeaponTooltip = new QCheckBox(groupGame);
            WeaponTooltip->setText(QCheckBox::tr("Show ammo menu tooltips"));
            groupGame->layout()->addWidget(WeaponTooltip, 9, 0, 1, 2);

            groupGame->addDivider();

            lblTags = new QLabel(groupGame);
            lblTags->setText(QLabel::tr("Displayed tags above hogs and translucent tags"));
            groupGame->layout()->addWidget(lblTags, 11, 0, 1, 2);

            tagsContainer = new QWidget();
            QHBoxLayout * tagsLayout = new QHBoxLayout(tagsContainer);
            tagsLayout->setSpacing(0);
            groupGame->layout()->addWidget(tagsContainer, 12, 0, 1, 2);

            CBTeamTag = new QCheckBox(groupGame);
            CBTeamTag->setText(QCheckBox::tr("Team"));
            CBTeamTag->setWhatsThis(QCheckBox::tr("Enable team tags by default"));

            CBHogTag = new QCheckBox(groupGame);
            CBHogTag->setText(QCheckBox::tr("Hog"));
            CBHogTag->setWhatsThis(QCheckBox::tr("Enable hedgehog tags by default"));

            CBHealthTag = new QCheckBox(groupGame);
            CBHealthTag->setText(QCheckBox::tr("Health"));
            CBHealthTag->setWhatsThis(QCheckBox::tr("Enable health tags by default"));

            CBTagOpacity = new QCheckBox(groupGame);
            CBTagOpacity->setText(QCheckBox::tr("Translucent"));
            CBTagOpacity->setWhatsThis(QCheckBox::tr("Enable translucent tags by default"));

            tagsLayout->addWidget(CBTeamTag, 0);
            tagsLayout->addWidget(CBHogTag, 0);
            tagsLayout->addWidget(CBHealthTag, 0);
            tagsLayout->addWidget(CBTagOpacity, 0);
            tagsLayout->addStretch(1);
        }

        { // group: frontend
            OptionGroupBox * groupFrontend = new OptionGroupBox(":/res/frontendicon.png", tr("Frontend"), this);
            rightColumn->addWidget(groupFrontend);

            // Fullscreen

            CBFrontendFullscreen = new QCheckBox(groupFrontend);
            CBFrontendFullscreen->setText(QCheckBox::tr("Fullscreen"));
            groupFrontend->layout()->addWidget(CBFrontendFullscreen, 0, 0);

            // Visual effects

            CBFrontendEffects = new QCheckBox(groupFrontend);
            CBFrontendEffects->setText(QCheckBox::tr("Visual effects"));
            CBFrontendEffects->setWhatsThis(QCheckBox::tr("Enable visual effects such as animated menu transitions and falling stars"));
            groupFrontend->layout()->addWidget(CBFrontendEffects, 1, 0);
        }

        { // group: colors
            OptionGroupBox * groupColors = new OptionGroupBox(":/res/Palette.png", tr("Custom colors"), this);
            rightColumn->addWidget(groupColors);

            groupColors->layout()->setColumnStretch(0, 1);
            groupColors->layout()->setColumnStretch(1, 1);
            groupColors->layout()->setColumnStretch(2, 1);

            // Color buttons

            QSignalMapper * mapper = new QSignalMapper(this);
            QStandardItemModel * model = DataManager::instance().colorsModel();

            connect(model, SIGNAL(dataChanged(QModelIndex,QModelIndex)), this, SLOT(onColorModelDataChanged(QModelIndex,QModelIndex)));
            for(int i = 0; i < model->rowCount(); ++i)
            {
                QPushButton * btn = new QPushButton(this);
                btn->setSizePolicy(QSizePolicy::Minimum, QSizePolicy::Minimum);
                groupColors->layout()->addWidget(btn, i / 3, i % 3);
                btn->setStyleSheet(QString("background: %1").arg(model->item(i)->data().value<QColor>().name()));
                m_colorButtons.append(btn);
                connect(btn, SIGNAL(clicked()), mapper, SLOT(map()));
                mapper->setMapping(btn, i);
            }

            connect(mapper, SIGNAL(mapped(int)), this, SLOT(colorButtonClicked(int)));

            // Reset default colors

            QPushButton * btn = new QPushButton(this);
            groupColors->layout()->addWidget(btn, (model->rowCount() - 1) / 3 + 1, 0, 1, 3);
            btn->setText(tr("Reset to default colors"));
            connect(btn, SIGNAL(clicked()), &DataManager::instance(), SLOT(resetColors()));
        }

        leftColumn->addStretch(1);
        rightColumn->addStretch(1);
    }

    { // audio page
        QVBoxLayout * leftColumn, * rightColumn;
        setupTabPage(pageAudio, &leftColumn, &rightColumn);

        { // group: game
            OptionGroupBox * groupGame = new OptionGroupBox(":/res/audio.png", tr("Game audio"), this);
            leftColumn->addWidget(groupGame);
            groupGame->layout()->setColumnStretch(1, 0);
            groupGame->layout()->setColumnStretch(2, 1);

            // Initial sound volume

            QLabel * vol = new QLabel(groupGame);
            vol->setText(QLabel::tr("Initial sound volume"));
            groupGame->layout()->addWidget(vol, 0, 0);

            SLVolume = new QSlider(Qt::Horizontal, groupGame);
            SLVolume->setTickPosition(QSlider::TicksBelow);
            SLVolume->setMaximum(100);
            SLVolume->setMinimum(0);
            SLVolume->setFixedWidth(150);
            groupGame->layout()->addWidget(SLVolume, 0, 1, 1, 2);

            lblVolumeLevel = new QLabel(groupGame);
            lblVolumeLevel->setFixedWidth(40);
            groupGame->layout()->addWidget(lblVolumeLevel, 0, 3);

            // Sound

            CBSound = new QCheckBox(groupGame);
            CBSound->setText(QCheckBox::tr("Sound"));
            CBSound->setWhatsThis(QCheckBox::tr("In-game sound effects"));
            groupGame->layout()->addWidget(CBSound, 1, 1);

            // Music

            CBMusic = new QCheckBox(groupGame);
            CBMusic->setText(QCheckBox::tr("Music"));
            CBMusic->setWhatsThis(QCheckBox::tr("In-game music"));
            groupGame->layout()->addWidget(CBMusic, 1, 2, 1, 2, Qt::AlignLeft);
        }

        { // group: frontend
            OptionGroupBox * groupFrontend = new OptionGroupBox(":/res/audio.png", tr("Frontend audio"), this);
            rightColumn->addWidget(groupFrontend);

            CBFrontendSound = new QCheckBox(groupFrontend);
            CBFrontendSound->setText(QCheckBox::tr("Sound"));
            CBFrontendSound->setWhatsThis(QCheckBox::tr("Frontend sound effects"));
            groupFrontend->layout()->addWidget(CBFrontendSound, 0, 0);

            CBFrontendMusic = new QCheckBox(groupFrontend);
            CBFrontendMusic->setText(QCheckBox::tr("Music"));
            CBFrontendMusic->setWhatsThis(QCheckBox::tr("Frontend music"));
            groupFrontend->layout()->addWidget(CBFrontendMusic, 0, 1);
        }

        leftColumn->addStretch(1);
        rightColumn->addStretch(1);
    }

    { // network page
        QVBoxLayout * leftColumn, * rightColumn;
        setupTabPage(pageNetwork, &leftColumn, &rightColumn);

        { // group: account
            OptionGroupBox * groupAccount = new OptionGroupBox(":/res/teamicon.png", tr("Account"), this);
            leftColumn->addWidget(groupAccount);

            // Label and field for net nick

            labelNN = new QLabel(groupAccount);
            labelNN->setText(QLabel::tr("Nickname"));
            groupAccount->layout()->addWidget(labelNN, 0, 0);

            editNetNick = new QLineEdit(groupAccount);
            editNetNick->setMaxLength(20);
            editNetNick->setText(QLineEdit::tr("anonymous"));
            groupAccount->layout()->addWidget(editNetNick, 0, 1);

            // Checkbox and field for password

            CBSavePassword = new QCheckBox(groupAccount);
            CBSavePassword->setText(QCheckBox::tr("Save password"));
            groupAccount->layout()->addWidget(CBSavePassword, 1, 0);

            editNetPassword = new QLineEdit(groupAccount);
            editNetPassword->setEchoMode(QLineEdit::Password);
            groupAccount->layout()->addWidget(editNetPassword, 1, 1);
        }

        { // group: proxy
            OptionGroupBox * groupProxy = new OptionGroupBox(":/res/net.png", tr("Proxy settings"), this);
            rightColumn->addWidget(groupProxy);

            // Labels

            QStringList sl;
            sl << tr("Proxy host")
               << tr("Proxy port")
               << tr("Proxy login")
               << tr("Proxy password");

            for(int i = 0; i < sl.size(); ++i)
            {
                QLabel * l = new QLabel(groupProxy);
                l->setText(sl[i]);
                groupProxy->layout()->addWidget(l, i + 1, 0);
            }

            // Proxy type

            cbProxyType = new QComboBox(groupProxy);
            cbProxyType->addItems(QStringList()
                                  << tr("No proxy")
                                  << tr("System proxy settings")
                                  << tr("Socks5 proxy")
                                  << tr("HTTP proxy"));
            groupProxy->layout()->addWidget(cbProxyType, 0, 0, 1, 2);

            // Proxy

            leProxy = new QLineEdit(groupProxy);
            groupProxy->layout()->addWidget(leProxy, 1, 1);

            // Proxy

            sbProxyPort = new QSpinBox(groupProxy);
            sbProxyPort->setMaximum(65535);
            groupProxy->layout()->addWidget(sbProxyPort, 2, 1);

            leProxyLogin = new QLineEdit(groupProxy);
            groupProxy->layout()->addWidget(leProxyLogin, 3, 1);

            leProxyPassword = new QLineEdit(groupProxy);
            leProxyPassword->setEchoMode(QLineEdit::Password);
            groupProxy->layout()->addWidget(leProxyPassword, 4, 1);


            connect(cbProxyType, SIGNAL(currentIndexChanged(int)), this, SLOT(onProxyTypeChanged()));
            onProxyTypeChanged();
        }

        leftColumn->addStretch(1);
        rightColumn->addStretch(1);
    }

    { // advanced page
        QVBoxLayout * leftColumn, * rightColumn;
        setupTabPage(pageAdvanced, &leftColumn, &rightColumn);

        { // group: miscellaneous
            OptionGroupBox * groupMisc = new OptionGroupBox(":/res/Settings.png", tr("Miscellaneous"), this);
            leftColumn->addWidget(groupMisc);

            // Language

            QLabel *labelLanguage = new QLabel(groupMisc);
            labelLanguage->setText(QLabel::tr("Locale"));
            groupMisc->layout()->addWidget(labelLanguage, 0, 0);

            CBLanguage = new QComboBox(groupMisc);
            CBLanguage->setMaxVisibleItems(50);
            groupMisc->layout()->addWidget(CBLanguage, 0, 1);
            QStringList locs = DataManager::instance().entryList("Locale", QDir::Files, QStringList("hedgewars_*.qm"));
            QStringList langnames;
            CBLanguage->addItem(QComboBox::tr("(System default)"), QString());
            for(int i = 0; i < locs.count(); i++)
            {
                QString lname = locs[i].replace(QRegExp("hedgewars_(.*)\\.qm"), "\\1");
                QLocale loc = QLocale(lname);
                QString entryName;
                // If local identifier has underscore, it means the country has been specified
                if(lname.contains("_"))
                {
                    // Append country name for disambiguation
                    // FIXME: These brackets are hardcoded and can't be translated. Luckily, these are rarely used and work with most languages anyway
                    entryName = loc.nativeLanguageName() + " (" + loc.nativeCountryName() + ")";
                }
                else
                {
                    // Usually, we just print the language name
                    entryName = loc.nativeLanguageName();
                }
                // Fallback code, if language name is empty for some reason. This should normally not happen
                if(entryName.isEmpty())
                {
                    // Show error and the locale identifier
                    entryName = tr("MISSING LANGUAGE NAME [%1]").arg(lname);
                }
                CBLanguage->addItem(entryName, lname);
            }

            QLabel *restartNoticeLabel = new QLabel(groupMisc);
            restartNoticeLabel->setText(QLabel::tr("This setting will be effective at next restart."));
            groupMisc->layout()->addWidget(restartNoticeLabel, 1, 1);


            // Divider

            groupMisc->addDivider(); // row 1

            // Append date and time to record file name

            CBNameWithDate = new QCheckBox(groupMisc);
            CBNameWithDate->setText(QCheckBox::tr("Append date and time to record file name"));
            CBNameWithDate->setWhatsThis(QCheckBox::tr("If enabled, Hedgewars adds the date and time in the form \"YYYY-MM-DD_hh-mm\" for automatically created demos."));
            groupMisc->layout()->addWidget(CBNameWithDate, 3, 0, 1, 2);

            // Associate file extensions

            BtnAssociateFiles = new QPushButton(groupMisc);
            BtnAssociateFiles->setText(QPushButton::tr("Associate file extensions"));
            BtnAssociateFiles->setVisible(!custom_data && !custom_config);
            groupMisc->layout()->addWidget(BtnAssociateFiles, 4, 0, 1, 2);

            // Divider

            groupMisc->addDivider(); // row 5

            QLabel *labelChatSize = new QLabel(groupMisc);
            labelChatSize->setText(QLabel::tr("Chat size in percent"));
            groupMisc->layout()->addWidget(labelChatSize, 6, 0);

            // Chat size adjustment
            sbChatSize = new QSpinBox(groupMisc);
            sbChatSize->setMinimum(80);
            sbChatSize->setMaximum(2000);
            sbChatSize->setValue(100);
            groupMisc->layout()->addWidget(sbChatSize, 6, 1);

        }

#ifdef __APPLE__
#ifdef SPARKLE_ENABLED
        { // group: updates
            OptionGroupBox * groupUpdates = new OptionGroupBox(":/res/net.png", tr("Updates"), this);
            rightColumn->addWidget(groupUpdates);

            // Check for updates at startup

            CBAutoUpdate = new QCheckBox(groupUpdates);
            CBAutoUpdate->setText(QCheckBox::tr("Check for updates at startup"));
            groupUpdates->layout()->addWidget(CBAutoUpdate, 0, 0);

            // Check for updates now

            btnUpdateNow = new QPushButton(groupUpdates);
            connect(btnUpdateNow, SIGNAL(clicked()), this, SLOT(checkForUpdates()));
            btnUpdateNow->setWhatsThis(tr("Check for updates"));
            btnUpdateNow->setText(tr("Check now"));
            btnUpdateNow->setFixedSize(130, 30);
            groupUpdates->layout()->addWidget(btnUpdateNow, 0, 1);
        }
#endif
#endif

        leftColumn->addStretch(1);
        rightColumn->addStretch(1);
    }

#ifdef VIDEOREC
    { // video recording page
        OptionGroupBox * groupVideoRec = new OptionGroupBox(":/res/camera.png", tr("Video recording options"), this);
        groupVideoRec->setMinimumWidth(500);
        groupVideoRec->setMaximumWidth(650);
        QHBoxLayout * layoutVideoRec = new QHBoxLayout(pageVideoRec);
        layoutVideoRec->addWidget(groupVideoRec, 1, Qt::AlignTop | Qt::AlignHCenter);

        // label for format

        QLabel *labelFormat = new QLabel(groupVideoRec);
        labelFormat->setText(QLabel::tr("Format"));
        groupVideoRec->layout()->addWidget(labelFormat, 0, 0);

        // list of supported formats

        comboAVFormats = new QComboBox(groupVideoRec);
        comboAVFormats->setMaxVisibleItems(50);
        groupVideoRec->layout()->addWidget(comboAVFormats, 0, 1, 1, 4);
        LibavInteraction::instance().fillFormats(comboAVFormats);

        // separator

        QFrame * hr = new QFrame(groupVideoRec);
        hr->setFrameStyle(QFrame::HLine);
        hr->setLineWidth(3);
        hr->setFixedHeight(10);
        groupVideoRec->layout()->addWidget(hr, 1, 0, 1, 5);

        // label for audio codec

        QLabel *labelACodec = new QLabel(groupVideoRec);
        labelACodec->setText(QLabel::tr("Audio codec"));
        groupVideoRec->layout()->addWidget(labelACodec, 2, 0);

        // list of supported audio codecs

        comboAudioCodecs = new QComboBox(groupVideoRec);
        comboAudioCodecs->setMaxVisibleItems(50);
        groupVideoRec->layout()->addWidget(comboAudioCodecs, 2, 1, 1, 3);

        // checkbox 'record audio'

        checkRecordAudio = new QCheckBox(groupVideoRec);
        checkRecordAudio->setText(QCheckBox::tr("Record audio"));
        groupVideoRec->layout()->addWidget(checkRecordAudio, 2, 4);

        // separator

        hr = new QFrame(groupVideoRec);
        hr->setFrameStyle(QFrame::HLine);
        hr->setLineWidth(3);
        hr->setFixedHeight(10);
        groupVideoRec->layout()->addWidget(hr, 3, 0, 1, 5);

        // label for video codec

        QLabel *labelVCodec = new QLabel(groupVideoRec);
        labelVCodec->setText(QLabel::tr("Video codec"));
        groupVideoRec->layout()->addWidget(labelVCodec, 4, 0);

        // list of supported video codecs

        comboVideoCodecs = new QComboBox(groupVideoRec);
        comboVideoCodecs->setMaxVisibleItems(50);
        groupVideoRec->layout()->addWidget(comboVideoCodecs, 4, 1, 1, 4);

        // label for resolution

        QLabel *labelRes = new QLabel(groupVideoRec);
        labelRes->setText(QLabel::tr("Resolution"));
        groupVideoRec->layout()->addWidget(labelRes, 5, 0);

        // width

        widthEdit = new QLineEdit(groupVideoRec);
        widthEdit->setValidator(new QIntValidator(this));
        groupVideoRec->layout()->addWidget(widthEdit, 5, 1);

        // multiplication sign

        QLabel *labelX = new QLabel(groupVideoRec);
        labelX->setText(tr("x"));
        groupVideoRec->layout()->addWidget(labelX, 5, 2);

        // height

        heightEdit = new QLineEdit(groupVideoRec);
        heightEdit->setValidator(new QIntValidator(groupVideoRec));
        groupVideoRec->layout()->addWidget(heightEdit, 5, 3);

        // checkbox 'use game resolution'

        checkUseGameRes = new QCheckBox(groupVideoRec);
        checkUseGameRes->setText(QCheckBox::tr("Use game resolution"));
        groupVideoRec->layout()->addWidget(checkUseGameRes, 5, 4);

        // label for framerate

        QLabel *labelFramerate = new QLabel(groupVideoRec);
        labelFramerate->setText(QLabel::tr("Framerate"));
        groupVideoRec->layout()->addWidget(labelFramerate, 6, 0);

        framerateBox = new QComboBox(groupVideoRec);
        framerateBox->addItem(QComboBox::tr("24 FPS"), 24);
        framerateBox->addItem(QComboBox::tr("25 FPS"), 25);
        framerateBox->addItem(QComboBox::tr("30 FPS"), 30);
        framerateBox->addItem(QComboBox::tr("50 FPS"), 50);
        framerateBox->addItem(QComboBox::tr("60 FPS"), 60);
        groupVideoRec->layout()->addWidget(framerateBox, 6, 1);

        // label for Bitrate

        QLabel *labelBitrate = new QLabel(groupVideoRec);
        //: “Kibit/s” is the symbol for 1024 bits per second
        labelBitrate->setText(QLabel::tr("Bitrate (Kibit/s)"));
        groupVideoRec->layout()->addWidget(labelBitrate, 6, 2);

        // bitrate

        bitrateBox = new QSpinBox(groupVideoRec);
        bitrateBox->setRange(100, 5000);
        bitrateBox->setSingleStep(100);
        bitrateBox->setWhatsThis(QSpinBox::tr("Specify the bitrate of recorded videos as a multiple of 1024 bits per second"));
        groupVideoRec->layout()->addWidget(bitrateBox, 6, 3);

        // button 'set default options'

        btnDefaults = new QPushButton(groupVideoRec);
        btnDefaults->setText(QPushButton::tr("Set default options"));
        btnDefaults->setWhatsThis(QPushButton::tr("Restore default coding parameters"));
        groupVideoRec->layout()->addWidget(btnDefaults, 7, 0, 1, 5);
    }
#endif

    previousQuality = this->SLQuality->value();
    previousResolutionIndex = this->CBResolution->currentIndex();
    previousFullscreenValue = this->CBFullscreen->isChecked();

    setFullscreen(CBFullscreen->isChecked());
    setVolume(SLVolume->value());

    // mutually exclude window and fullscreen resolution
    return pageLayout;
}

QLayout * PageOptions::footerLayoutDefinition()
{
    return NULL;
}

void PageOptions::connectSignals()
{
#ifdef VIDEOREC
    connect(checkUseGameRes, SIGNAL(stateChanged(int)), this, SLOT(changeUseGameRes(int)));
    connect(checkRecordAudio, SIGNAL(stateChanged(int)), this, SLOT(changeRecordAudio(int)));
    connect(comboAVFormats, SIGNAL(currentIndexChanged(int)), this, SLOT(changeAVFormat(int)));
    connect(btnDefaults, SIGNAL(clicked()), this, SLOT(setDefaultOptions()));
#endif
    //connect(this, SIGNAL(pageEnter()), this, SLOT(setTeamOptionsEnabled()));
    connect(SLVolume, SIGNAL(valueChanged(int)), this, SLOT(setVolume(int)));
    connect(SLQuality, SIGNAL(valueChanged(int)), this, SLOT(setQuality(int)));
    connect(CBResolution, SIGNAL(currentIndexChanged(int)), this, SLOT(setResolution(int)));
    connect(CBFullscreen, SIGNAL(stateChanged(int)), this, SLOT(setFullscreen(int)));
    connect(CBStereoMode, SIGNAL(currentIndexChanged(int)), this, SLOT(forceFullscreen(int)));
    connect(editNetNick, SIGNAL(editingFinished()), this, SLOT(trimNetNick()));
    connect(CBSavePassword, SIGNAL(stateChanged(int)), this, SLOT(savePwdChanged(int)));
}

void PageOptions::setVolume(int volume)
{
    lblVolumeLevel->setText(QString("%1\%").arg(volume));
}

void PageOptions::setupTabPage(QWidget * tabpage, QVBoxLayout ** leftColumn, QVBoxLayout ** rightColumn)
{
    QHBoxLayout * twoColumns = new QHBoxLayout(tabpage);
    twoColumns->setSpacing(0);
    *leftColumn = new QVBoxLayout();
    *rightColumn = new QVBoxLayout();
    (*leftColumn)->setSpacing(OPTION_BOX_SPACING);
    (*rightColumn)->setSpacing(OPTION_BOX_SPACING);
    twoColumns->addStretch(4);
    twoColumns->addLayout(*leftColumn, 0);
    twoColumns->addStretch(1);
    twoColumns->addLayout(*rightColumn, 0);
    twoColumns->addStretch(4);
}

PageOptions::PageOptions(QWidget* parent) : AbstractPage(parent), config(0)
{
    initPage();
}

void PageOptions::forceFullscreen(int index)
{
    bool forced = (index == 7 || index == 8 || index == 9);

    if (index != 0)
    {
        this->SLQuality->setValue(this->SLQuality->maximum());
        this->SLQuality->setEnabled(false);
        this->CBFullscreen->setChecked(forced ? true : previousFullscreenValue);
        setFullscreen(forced ? true : previousFullscreenValue);
        this->CBResolution->setCurrentIndex(forced ? 0 : previousResolutionIndex);
    }
    else
    {
        this->SLQuality->setEnabled(true);
        this->SLQuality->setValue(previousQuality);
        this->CBFullscreen->setChecked(previousFullscreenValue);
        setFullscreen(previousFullscreenValue);
        this->CBResolution->setCurrentIndex(previousResolutionIndex);
    }
}

void PageOptions::setQuality(int value)
{
    Q_UNUSED(value);

    int index = this->CBStereoMode->currentIndex();
    if (index == 0)
        previousQuality = this->SLQuality->value();
}

void PageOptions::setFullscreen(int state)
{
    Q_UNUSED(state);

    lblFullScreenRes->setVisible(state);
    CBResolution->setVisible(state);
    lblWinScreenRes->setVisible(!state);
    winResContainer->setVisible(!state);

    int index = this->CBStereoMode->currentIndex();
    if (index != 7 && index != 8 && index != 9)
        previousFullscreenValue = this->CBFullscreen->isChecked();
}

void PageOptions::setResolution(int state)
{
    Q_UNUSED(state);

    int index = this->CBStereoMode->currentIndex();
    if (index != 7 && index != 8 && index != 9)
        previousResolutionIndex = this->CBResolution->currentIndex();
}

void PageOptions::trimNetNick()
{
    editNetNick->setText(editNetNick->text().trimmed());
}

void PageOptions::savePwdChanged(int state) {
    if (state == 0) {
        editNetPassword->setEnabled(false);
        editNetPassword->setText("");
    } else
        editNetPassword->setEnabled(true);
}

void PageOptions::requestEditSelectedTeam()
{
    emit editTeamRequested(CBTeamName->currentText());
}

void PageOptions::requestDeleteSelectedTeam()
{
    if(CBTeamName->count() > 1)
        emit deleteTeamRequested(CBTeamName->currentText());
    else
        QMessageBox::warning(this, tr("Can't delete last team"), tr("You can't delete the last team!"));
}

void PageOptions::setTeamOptionsEnabled(bool enabled)
{
    BtnNewTeam->setVisible(enabled);
    BtnEditTeam->setVisible(enabled);
    BtnDeleteTeam->setVisible(enabled);
    CBTeamName->setVisible(enabled);
    LblNoEditTeam->setVisible(!enabled);
}

void PageOptions::colorButtonClicked(int i)
{
    if(i < 0 || i >= m_colorButtons.size())
        return;

    QPalette p = m_colorButtons[i]->palette();
    QColor c = QColorDialog::getColor(p.color(QPalette::Button));

    if(c.isValid())
    {
        DataManager::instance().colorsModel()->item(i)->setData(c);
        m_colorButtons[i]->setStyleSheet(QString("background: %1").arg(c.name()));
    }
}

void PageOptions::onColorModelDataChanged(const QModelIndex & topLeft, const QModelIndex & bottomRight)
{
    Q_UNUSED(bottomRight);

    QStandardItemModel * model = DataManager::instance().colorsModel();

    m_colorButtons[topLeft.row()]->setStyleSheet(QString("background: %1").arg(model->item(topLeft.row())->data().value<QColor>().name()));
}

void PageOptions::onProxyTypeChanged()
{
    bool b = cbProxyType->currentIndex() != NoProxy && cbProxyType->currentIndex() != SystemProxy ;

    sbProxyPort->setEnabled(b);
    leProxy->setEnabled(b);
    leProxyLogin->setEnabled(b);
    leProxyPassword->setEnabled(b);
}

// Video Recording

void PageOptions::setConfig(GameUIConfig * config)
{
    this->config = config;
}

// user changed file format, we need to update list of codecs
void PageOptions::changeAVFormat(int index)
{
    // remember selected codecs
    QString prevVCodec = videoCodec();
    QString prevACodec = audioCodec();

    // clear lists of codecs
    comboVideoCodecs->clear();
    comboAudioCodecs->clear();

    // get list of codecs for specified format
    LibavInteraction::instance().fillCodecs(comboAVFormats->itemData(index).toString(), comboVideoCodecs, comboAudioCodecs);

    // disable audio if there is no audio codec
    if (comboAudioCodecs->count() == 0)
    {
        checkRecordAudio->setChecked(false);
        checkRecordAudio->setEnabled(false);
    }
    else
        checkRecordAudio->setEnabled(true);

    // restore selected codecs if possible
    int iVCodec = comboVideoCodecs->findData(prevVCodec);
    if (iVCodec != -1)
        comboVideoCodecs->setCurrentIndex(iVCodec);
    int iACodec = comboAudioCodecs->findData(prevACodec);
    if (iACodec != -1)
        comboAudioCodecs->setCurrentIndex(iACodec);
}

// user switched checkbox 'use game resolution'
void PageOptions::changeUseGameRes(int state)
{
    if (state && config)
    {
        // set resolution to game resolution
        QRect resolution = config->vid_Resolution();
        widthEdit->setText(QString::number(resolution.width()));
        heightEdit->setText(QString::number(resolution.height()));
    }
    widthEdit->setEnabled(!state);
    heightEdit->setEnabled(!state);
}

// user switched checkbox 'record audio'
void PageOptions::changeRecordAudio(int state)
{
    comboAudioCodecs->setEnabled(!!state);
}

void PageOptions::setDefaultCodecs()
{
    // VLC should be able to handle any of these configurations
    // Quicktime X only opens the first one
    // Windows Media Player TODO
    if (tryCodecs("mp4", "libx264", "aac"))
        return;
    if (tryCodecs("mp4", "libx264", "libfaac"))
        return;
    if (tryCodecs("mp4", "libx264", "libmp3lame"))
        return;
    if (tryCodecs("mp4", "libx264", "mp2"))
        return;
    if (tryCodecs("avi", "libxvid", "libmp3lame"))
        return;
    if (tryCodecs("avi", "libxvid", "ac3_fixed"))
        return;
    if (tryCodecs("avi", "libxvid", "mp2"))
        return;
    if (tryCodecs("avi", "mpeg4", "libmp3lame"))
        return;
    if (tryCodecs("avi", "mpeg4", "ac3_fixed"))
        return;
    if (tryCodecs("avi", "mpeg4", "mp2"))
        return;

    // this shouldn't happen, just in case
    if (tryCodecs("ogg", "libtheora", "libvorbis"))
        return;
    tryCodecs("ogg", "libtheora", "flac");
}

void PageOptions::setDefaultOptions()
{
    framerateBox->setCurrentIndex(2);
    bitrateBox->setValue(1000);
    checkRecordAudio->setChecked(true);
    checkUseGameRes->setChecked(true);
    setDefaultCodecs();
}

void PageOptions::checkForUpdates()
{
    AutoUpdater *updater = NULL;

#ifdef __APPLE__
#ifdef SPARKLE_ENABLED
    updater = new SparkleAutoUpdater();
#endif
#endif

    if (updater)
    {
        updater->checkForUpdatesNow();
        delete updater;
    }
}

bool PageOptions::tryCodecs(const QString & format, const QString & vcodec, const QString & acodec)
{
    // first we should change format
    int iFormat = comboAVFormats->findData(format);
    if (iFormat == -1)
        return false;
    comboAVFormats->setCurrentIndex(iFormat);
    // format was changed, so lists of codecs were automatically updated to codecs supported by this format

    // try to find video codec
    int iVCodec = comboVideoCodecs->findData(vcodec);
    if (iVCodec == -1)
        return false;
    comboVideoCodecs->setCurrentIndex(iVCodec);

    // try to find audio codec
    int iACodec = comboAudioCodecs->findData(acodec);
    if (iACodec == -1 && checkRecordAudio->isChecked())
        return false;
    if (iACodec != -1)
        comboAudioCodecs->setCurrentIndex(iACodec);

    return true;
}

// When the current tab is switched
void PageOptions::tabIndexChanged(int index)
{
    if (index == binderTab) // Switched to bind tab
    {
        binder->resetInterface();

        if (!config) return;

        QStandardItemModel * binds = DataManager::instance().bindsModel();
        for(int i = 0; i < BINDS_NUMBER; i++)
        {
            QString value = config->bind(i);
            QModelIndexList mdl = binds->match(binds->index(0, 0), Qt::UserRole + 1, value, 1, Qt::MatchExactly);
            if(mdl.size() == 1) binder->setBindIndex(i, mdl[0].row());
        }
    }

    currentTab = index;
}

// When a key bind combobox is changed
void PageOptions::bindUpdated(int bindID)
{
    int bindIndex = binder->bindIndex(bindID);

    if (bindIndex == 0) bindIndex = resetBindToDefault(bindID);

    // Save bind
    QStandardItemModel * binds = DataManager::instance().bindsModel();
    QString strbind = binds->index(binder->bindIndex(bindID), 0).data(Qt::UserRole + 1).toString();
    config->setBind(bindID, strbind);
}

// Changes a key bind (bindID) to its default value. This updates the bind's combo-box in the UI.
// Returns: The bind model index of the default.
int PageOptions::resetBindToDefault(int bindID)
{
    QStandardItemModel * binds = DataManager::instance().bindsModel();
    QModelIndexList mdl = binds->match(binds->index(0, 0), Qt::UserRole + 1, cbinds[bindID].strbind, 1, Qt::MatchExactly);
    if(mdl.size() == 1) binder->setBindIndex(bindID, mdl[0].row());
    return mdl[0].row();
}

// Called when "reset all binds" button is pressed
void PageOptions::resetAllBinds()
{
    for (int i = 0; i < BINDS_NUMBER; i++)
    {
        resetBindToDefault(i);
        bindUpdated(i);
    }
}
