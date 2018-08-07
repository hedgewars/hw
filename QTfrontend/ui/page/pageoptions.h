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

#ifndef PAGE_OPTIONS_H
#define PAGE_OPTIONS_H

#include "igbox.h"
#include "AbstractPage.h"

#include <QString>

class GameUIConfig;
class FPSEdit;
class QSignalMapper;
class KeyBinder;
class QGridLayout;

// Let's stay D-R-Y
class OptionGroupBox : public IconedGroupBox
{
    Q_OBJECT

    public:
        OptionGroupBox(const QString & iconName,
                       const QString & title,
                       QWidget * parent = 0);
        QGridLayout * layout();
        void addDivider();

    private:
        QGridLayout * m_layout;
};

class PageOptions : public AbstractPage
{
        Q_OBJECT

    public:
        enum ProxyTypes {
            NoProxy      = 0,
            SystemProxy  = 1,
            Socks5Proxy  = 2,
            HTTPProxy    = 3
        };

        PageOptions(QWidget* parent = 0);

        QCheckBox *WeaponTooltip;
        QPushButton *WeaponNew;
        QPushButton *WeaponEdit;
        QPushButton *WeaponDelete;
        QComboBox *WeaponsName;
        QPushButton *SchemeNew;
        QPushButton *SchemeEdit;
        QPushButton *SchemeDelete;
        QComboBox *SchemesName;

        QComboBox *CBLanguage;

        IconedGroupBox *teamsBox;
        QPushButton *BtnAssociateFiles;
        QComboBox *CBTeamName;
        IconedGroupBox *AGGroupBox;
        QComboBox *CBResolution;
        QSpinBox *windowWidthEdit;
        QSpinBox *windowHeightEdit;
        QComboBox *CBStereoMode;
        QCheckBox *CBFrontendSound;
        QCheckBox *CBFrontendMusic;
        QCheckBox *CBSound;
        QCheckBox *CBMusic;
        QCheckBox *CBDampenAudio;
        QCheckBox *CBFullscreen;
        QCheckBox *CBFrontendFullscreen;
        QCheckBox *CBShowFPS;
        QCheckBox *CBSavePassword;
        QCheckBox *CBAltDamage;
        QCheckBox *CBNameWithDate;


        QCheckBox *CBTeamTag;
        QCheckBox *CBHogTag;
        QCheckBox *CBHealthTag;
        QCheckBox *CBTagOpacity;

#ifdef __APPLE__
        QCheckBox *CBAutoUpdate;
        QPushButton *BtnUpdateNow;
#endif

        FPSEdit *fpsedit;
        QLabel *labelNN;
        QSlider *SLVolume;
        QLabel *lblVolumeLevel;
        QLineEdit *editNetNick;
        QLineEdit *editNetPassword;
        QSlider *SLQuality;
        QCheckBox *CBFrontendEffects;
        QComboBox * cbProxyType;
        QSpinBox * sbProxyPort;
        QLineEdit * leProxy;
        QLineEdit * leProxyLogin;
        QLineEdit * leProxyPassword;

        QComboBox  *framerateBox;
        QSpinBox  *bitrateBox;
        QLineEdit *widthEdit;
        QLineEdit *heightEdit;
        QCheckBox *checkUseGameRes;
        QCheckBox *checkRecordAudio;

        QString format()
        { return comboAVFormats->itemData(comboAVFormats->currentIndex()).toString(); }

        QString videoCodec()
        { return comboVideoCodecs->itemData(comboVideoCodecs->currentIndex()).toString(); }

        QString audioCodec()
        { return comboAudioCodecs->itemData(comboAudioCodecs->currentIndex()).toString(); }

        void setDefaultCodecs();
        bool tryCodecs(const QString & format, const QString & vcodec, const QString & acodec);
        void setConfig(GameUIConfig * config);

        void setTeamOptionsEnabled(bool enabled);

    signals:
        void newTeamRequested();
        void editTeamRequested(const QString & teamName);
        void deleteTeamRequested(const QString & teamName);


    private:
        QLayout * bodyLayoutDefinition();
        QLayout * footerLayoutDefinition();
        void connectSignals();
        int resetBindToDefault(int bindID);
        void setupTabPage(QWidget * tabpage, QVBoxLayout ** leftColumn, QVBoxLayout ** rightColumn);

        bool previousFullscreenValue;
        int previousResolutionIndex;
        int previousQuality;
        QLabel *LblNoEditTeam;
        QPushButton *BtnNewTeam;
        QPushButton *BtnEditTeam;
        QPushButton *BtnDeleteTeam;
        QList<QPushButton *> m_colorButtons;

        QComboBox *comboAVFormats;
        QComboBox *comboVideoCodecs;
        QComboBox *comboAudioCodecs;
        QPushButton *btnDefaults;
        QPushButton *btnUpdateNow;
        GameUIConfig * config;
        KeyBinder * binder;
        int currentTab;
        int binderTab;

        QLabel * lblFullScreenRes;
        QLabel * lblWinScreenRes;
        QLabel * lblTags;
        QWidget * winResContainer;
        QWidget * tagsContainer;

    private slots:
        void forceFullscreen(int index);
        void setFullscreen(int state);
        void setResolution(int state);
        void setQuality(int value);
        void trimNetNick();
        void requestEditSelectedTeam();
        void requestDeleteSelectedTeam();
        void savePwdChanged(int state);
        void colorButtonClicked(int i);
        void onColorModelDataChanged(const QModelIndex & topLeft, const QModelIndex & bottomRight);
        void onProxyTypeChanged();
        void changeAVFormat(int index);
        void changeUseGameRes(int state);
        void changeRecordAudio(int state);
        void checkForUpdates();
        void tabIndexChanged(int);
        void bindUpdated(int bindID);
        void resetAllBinds();
        void setVolume(int);

    public slots:
        void setDefaultOptions();
};

#endif

