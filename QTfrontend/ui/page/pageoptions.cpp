/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

#include <QGridLayout>
#include <QHBoxLayout>
#include <QPushButton>
#include <QGroupBox>
#include <QComboBox>
#include <QCheckBox>
#include <QLabel>
#include <QLineEdit>
#include <QSpinBox>
#include <QTextBrowser>
#include <QTableWidget>
#include <QSlider>
#include <QSignalMapper>
#include <QColorDialog>
#include <QStandardItemModel>

#include "pageoptions.h"
#include "hwconsts.h"
#include "fpsedit.h"
#include "igbox.h"
#include "DataManager.h"

// TODO cleanup
QLayout * PageOptions::bodyLayoutDefinition()
{
    QVBoxLayout * pageLayout = new QVBoxLayout();

    QTabWidget * tabs = new QTabWidget(this);
    pageLayout->addWidget(tabs);
    QWidget * page1 = new QWidget(this);
    QWidget * page2 = new QWidget(this);
    tabs->addTab(page1, tr("General"));
    tabs->addTab(page2, tr("Advanced"));

    { // page 1
        QGridLayout * page1Layout = new QGridLayout(page1);
        //gbTBLayout->setMargin(0);
        page1Layout->setSpacing(0);
        page1Layout->setAlignment(Qt::AlignTop | Qt::AlignLeft);

        QPixmap pmNew(":/res/new.png");
        QPixmap pmEdit(":/res/edit.png");
        QPixmap pmDelete(":/res/delete.png");

        {
            teamsBox = new IconedGroupBox(this);
            //teamsBox->setContentTopPadding(0);
            //teamsBox->setAttribute(Qt::WA_PaintOnScreen, true);
            teamsBox->setIcon(QIcon(":/res/teamicon.png"));
            teamsBox->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
            teamsBox->setTitle(QGroupBox::tr("Teams"));

            QGridLayout * GBTlayout = new QGridLayout(teamsBox);

            CBTeamName = new QComboBox(teamsBox);
            GBTlayout->addWidget(CBTeamName, 0, 0);

            BtnNewTeam = new QPushButton(teamsBox);
            BtnNewTeam->setToolTip(tr("New team"));
            BtnNewTeam->setIconSize(pmNew.size());
            BtnNewTeam->setIcon(pmNew);
            BtnNewTeam->setMaximumWidth(pmNew.width() + 6);
            connect(BtnNewTeam, SIGNAL(clicked()), this, SIGNAL(newTeamRequested()));
            GBTlayout->addWidget(BtnNewTeam, 0, 1);

            BtnEditTeam = new QPushButton(teamsBox);
            BtnEditTeam->setToolTip(tr("Edit team"));
            BtnEditTeam->setIconSize(pmEdit.size());
            BtnEditTeam->setIcon(pmEdit);
            BtnEditTeam->setMaximumWidth(pmEdit.width() + 6);
            connect(BtnEditTeam, SIGNAL(clicked()), this, SLOT(requestEditSelectedTeam()));
            GBTlayout->addWidget(BtnEditTeam, 0, 2);

            BtnDeleteTeam = new QPushButton(teamsBox);
            BtnDeleteTeam->setToolTip(tr("Delete team"));
            BtnDeleteTeam->setIconSize(pmDelete.size());
            BtnDeleteTeam->setIcon(pmDelete);
            BtnDeleteTeam->setMaximumWidth(pmDelete.width() + 6);
            connect(BtnDeleteTeam, SIGNAL(clicked()), this, SLOT(requestDeleteSelectedTeam()));
            GBTlayout->addWidget(BtnDeleteTeam, 0, 3);

            LblNoEditTeam = new QLabel(teamsBox);
            LblNoEditTeam->setText(tr("You can't edit teams from team selection. Go back to main menu to add, edit or delete teams."));
            LblNoEditTeam->setWordWrap(true);
            LblNoEditTeam->setVisible(false);
            GBTlayout->addWidget(LblNoEditTeam, 0, 0);

            page1Layout->addWidget(teamsBox, 0, 0);
        }

        {
            IconedGroupBox* groupWeapons = new IconedGroupBox(this);

            //groupWeapons->setContentTopPadding(0);
            //groupWeapons->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
            groupWeapons->setIcon(QIcon(":/res/weaponsicon.png"));
            groupWeapons->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
            groupWeapons->setTitle(QGroupBox::tr("Schemes and Weapons"));
            QGridLayout * WeaponsLayout = new QGridLayout(groupWeapons);

            QLabel* SchemeLabel = new QLabel(groupWeapons);
            SchemeLabel->setText(QLabel::tr("Game scheme"));
            WeaponsLayout->addWidget(SchemeLabel, 1, 0);

            SchemesName = new QComboBox(groupWeapons);
            WeaponsLayout->addWidget(SchemesName, 1, 1);

            SchemeNew = new QPushButton(groupWeapons);
            SchemeNew->setWhatsThis(tr("New scheme"));
            SchemeNew->setIconSize(pmNew.size());
            SchemeNew->setIcon(pmNew);
            SchemeNew->setMaximumWidth(pmNew.width() + 6);
            WeaponsLayout->addWidget(SchemeNew, 1, 2);

            SchemeEdit = new QPushButton(groupWeapons);
            SchemeEdit->setWhatsThis(tr("Edit scheme"));
            SchemeEdit->setIconSize(pmEdit.size());
            SchemeEdit->setIcon(pmEdit);
            SchemeEdit->setMaximumWidth(pmEdit.width() + 6);
            WeaponsLayout->addWidget(SchemeEdit, 1, 3);

            SchemeDelete = new QPushButton(groupWeapons);
            SchemeDelete->setWhatsThis(tr("Delete scheme"));
            SchemeDelete->setIconSize(pmDelete.size());
            SchemeDelete->setIcon(pmDelete);
            SchemeDelete->setMaximumWidth(pmDelete.width() + 6);
            WeaponsLayout->addWidget(SchemeDelete, 1, 4);

            QLabel* WeaponLabel = new QLabel(groupWeapons);
            WeaponLabel->setText(QLabel::tr("Weapons"));
            WeaponsLayout->addWidget(WeaponLabel, 2, 0);

            WeaponsName = new QComboBox(groupWeapons);
            WeaponsLayout->addWidget(WeaponsName, 2, 1);

            WeaponNew = new QPushButton(groupWeapons);
            WeaponNew->setWhatsThis(tr("New weapon set"));
            WeaponNew->setIconSize(pmNew.size());
            WeaponNew->setIcon(pmNew);
            WeaponNew->setMaximumWidth(pmNew.width() + 6);
            WeaponsLayout->addWidget(WeaponNew, 2, 2);

            WeaponEdit = new QPushButton(groupWeapons);
            WeaponEdit->setWhatsThis(tr("Edit weapon set"));
            WeaponEdit->setIconSize(pmEdit.size());
            WeaponEdit->setIcon(pmEdit);
            WeaponEdit->setMaximumWidth(pmEdit.width() + 6);
            WeaponsLayout->addWidget(WeaponEdit, 2, 3);

            WeaponDelete = new QPushButton(groupWeapons);
            WeaponDelete->setWhatsThis(tr("Delete weapon set"));
            WeaponDelete->setIconSize(pmDelete.size());
            WeaponDelete->setIcon(pmDelete);
            WeaponDelete->setMaximumWidth(pmDelete.width() + 6);
            WeaponsLayout->addWidget(WeaponDelete, 2, 4);

            page1Layout->addWidget(groupWeapons, 1, 0);
        }

        {
            IconedGroupBox* groupMisc = new IconedGroupBox(this);
            //groupMisc->setContentTopPadding(0);
            //groupMisc->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::MinimumExpanding);
            groupMisc->setIcon(QIcon(":/res/miscicon.png"));
            //groupMisc->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
            groupMisc->setTitle(QGroupBox::tr("Misc"));
            QGridLayout * MiscLayout = new QGridLayout(groupMisc);

            // Label for "Language"
            QLabel *labelLanguage = new QLabel(groupMisc);
            labelLanguage->setText(QLabel::tr("Locale") + " *");
            MiscLayout->addWidget(labelLanguage, 0, 0);

            // List of installed languages
            CBLanguage = new QComboBox(groupMisc);
            QDir tmpdir;
            tmpdir.cd(cfgdir->absolutePath());
            tmpdir.cd("Data/Locale");
            tmpdir.setFilter(QDir::Files);
            QStringList locs = tmpdir.entryList(QStringList("hedgewars_*.qm"));
            CBLanguage->addItem(QComboBox::tr("(System default)"), QString(""));
            for(int i = 0; i < locs.count(); i++)
            {
                QLocale loc(locs[i].replace(QRegExp("hedgewars_(.*)\\.qm"), "\\1"));
                CBLanguage->addItem(QLocale::languageToString(loc.language()) + " (" + QLocale::countryToString(loc.country()) + ")", loc.name());
            }

            tmpdir.cd(datadir->absolutePath());
            tmpdir.cd("Locale");
            tmpdir.setFilter(QDir::Files);
            QStringList tmplist = tmpdir.entryList(QStringList("hedgewars_*.qm"));
            for(int i = 0; i < tmplist.count(); i++)
            {
                if (locs.contains(tmplist[i])) continue;
                QLocale loc(tmplist[i].replace(QRegExp("hedgewars_(.*)\\.qm"), "\\1"));
                CBLanguage->addItem(QLocale::languageToString(loc.language()) + " (" + QLocale::countryToString(loc.country()) + ")", loc.name());
            }

            MiscLayout->addWidget(CBLanguage, 0, 1);

            // Label and field for net nick
            labelNN = new QLabel(groupMisc);
            labelNN->setText(QLabel::tr("Nickname"));
            MiscLayout->addWidget(labelNN, 1, 0);

            editNetNick = new QLineEdit(groupMisc);
            editNetNick->setMaxLength(20);
            editNetNick->setText(QLineEdit::tr("anonymous"));
            MiscLayout->addWidget(editNetNick, 1, 1);

            // checkbox and field for password
            CBSavePassword = new QCheckBox(groupMisc);
            CBSavePassword->setText(QCheckBox::tr("Save password"));
            MiscLayout->addWidget(CBSavePassword, 2, 0);

            editNetPassword = new QLineEdit(groupMisc);
            editNetPassword->setEchoMode(QLineEdit::Password);
            MiscLayout->addWidget(editNetPassword, 2, 1);

    #ifdef __APPLE__
    #ifdef SPARKLE_ENABLED
            CBAutoUpdate = new QCheckBox(groupMisc);
            CBAutoUpdate->setText(QCheckBox::tr("Check for updates at startup"));
            MiscLayout->addWidget(CBAutoUpdate, 7, 0, 1, 3);
    #endif
    #endif
            page1Layout->addWidget(groupMisc, 2, 0);
        }

        {
            AGGroupBox = new IconedGroupBox(this);
            //AGGroupBox->setContentTopPadding(0);
            AGGroupBox->setIcon(QIcon(":/res/graphicsicon.png"));
            //AGGroupBox->setSizePolicy(QSizePolicy::MinimumExpanding, QSizePolicy::Fixed);
            AGGroupBox->setTitle(QGroupBox::tr("Audio/Graphic options"));

            QVBoxLayout * GBAlayout = new QVBoxLayout(AGGroupBox);
            QHBoxLayout * GBAreslayout = new QHBoxLayout(0);
            QHBoxLayout * GBAstereolayout = new QHBoxLayout(0);
            QHBoxLayout * GBAqualayout = new QHBoxLayout(0);

            CBFrontendFullscreen = new QCheckBox(AGGroupBox);
            CBFrontendFullscreen->setText(QCheckBox::tr("Frontend fullscreen"));
            GBAlayout->addWidget(CBFrontendFullscreen);

            CBFrontendEffects = new QCheckBox(AGGroupBox);
            CBFrontendEffects->setText(QCheckBox::tr("Frontend effects"));
            GBAlayout->addWidget(CBFrontendEffects);

            CBEnableFrontendSound = new QCheckBox(AGGroupBox);
            CBEnableFrontendSound->setText(QCheckBox::tr("Enable frontend sounds"));
            GBAlayout->addWidget(CBEnableFrontendSound);

            CBEnableFrontendMusic = new QCheckBox(AGGroupBox);
            CBEnableFrontendMusic->setText(QCheckBox::tr("Enable frontend music"));
            GBAlayout->addWidget(CBEnableFrontendMusic);

            QFrame * hr = new QFrame(AGGroupBox);
            hr->setFrameStyle(QFrame::HLine);
            hr->setLineWidth(3);
            hr->setFixedHeight(10);
            GBAlayout->addWidget(hr);

            QLabel * resolution = new QLabel(AGGroupBox);
            resolution->setText(QLabel::tr("Resolution"));
            GBAreslayout->addWidget(resolution);

            CBResolution = new QComboBox(AGGroupBox);
            GBAreslayout->addWidget(CBResolution);
            GBAlayout->addLayout(GBAreslayout);

            CBFullscreen = new QCheckBox(AGGroupBox);
            CBFullscreen->setText(QCheckBox::tr("Fullscreen"));
            GBAreslayout->addWidget(CBFullscreen);

            QLabel * quality = new QLabel(AGGroupBox);
            quality->setText(QLabel::tr("Quality"));
            quality->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
            GBAqualayout->addWidget(quality);

            SLQuality = new QSlider(Qt::Horizontal, AGGroupBox);
            SLQuality->setTickPosition(QSlider::TicksBelow);
            SLQuality->setMaximum(5);
            SLQuality->setMinimum(0);
            SLQuality->setFixedWidth(150);
            GBAqualayout->addWidget(SLQuality);
            GBAlayout->addLayout(GBAqualayout);

            QLabel * stereo = new QLabel(AGGroupBox);
            stereo->setText(QLabel::tr("Stereo rendering"));
            GBAstereolayout->addWidget(stereo);

            CBStereoMode = new QComboBox(AGGroupBox);
            CBStereoMode->addItem(QComboBox::tr("Disabled"));
            CBStereoMode->addItem(QComboBox::tr("Red/Cyan"));
            CBStereoMode->addItem(QComboBox::tr("Cyan/Red"));
            CBStereoMode->addItem(QComboBox::tr("Red/Blue"));
            CBStereoMode->addItem(QComboBox::tr("Blue/Red"));
            CBStereoMode->addItem(QComboBox::tr("Red/Green"));
            CBStereoMode->addItem(QComboBox::tr("Green/Red"));
            CBStereoMode->addItem(QComboBox::tr("Side-by-side"));
            CBStereoMode->addItem(QComboBox::tr("Top-Bottom"));
            CBStereoMode->addItem(QComboBox::tr("Wiggle"));
            CBStereoMode->addItem(QComboBox::tr("Red/Cyan grayscale"));
            CBStereoMode->addItem(QComboBox::tr("Cyan/Red grayscale"));
            CBStereoMode->addItem(QComboBox::tr("Red/Blue grayscale"));
            CBStereoMode->addItem(QComboBox::tr("Blue/Red grayscale"));
            CBStereoMode->addItem(QComboBox::tr("Red/Green grayscale"));
            CBStereoMode->addItem(QComboBox::tr("Green/Red grayscale"));

            GBAstereolayout->addWidget(CBStereoMode);
            GBAlayout->addLayout(GBAstereolayout);

            hr = new QFrame(AGGroupBox);
            hr->setFrameStyle(QFrame::HLine);
            hr->setLineWidth(3);
            hr->setFixedHeight(10);
            GBAlayout->addWidget(hr);

            QGridLayout * GBAvollayout = new QGridLayout();
            QLabel * vol = new QLabel(AGGroupBox);
            vol->setText(QLabel::tr("Initial sound volume"));
            GBAvollayout->addWidget(vol, 0, 0, 1, 2);
            GBAlayout->addLayout(GBAvollayout);
            volumeBox = new QSpinBox(AGGroupBox);
            volumeBox->setRange(0, 100);
            volumeBox->setSingleStep(5);
            GBAvollayout->addWidget(volumeBox, 0, 2);

            CBEnableSound = new QCheckBox(AGGroupBox);
            CBEnableSound->setText(QCheckBox::tr("Enable sound"));
            GBAvollayout->addWidget(CBEnableSound, 1, 0, 1, 1);

            CBEnableMusic = new QCheckBox(AGGroupBox);
            CBEnableMusic->setText(QCheckBox::tr("Enable music"));
            GBAvollayout->addWidget(CBEnableMusic, 1, 1, 1, 2);

            GBAvollayout->setSizeConstraint(QLayout::SetMinimumSize);

            hr = new QFrame(AGGroupBox);
            hr->setFrameStyle(QFrame::HLine);
            hr->setLineWidth(3);
            hr->setFixedHeight(10);
            GBAlayout->addWidget(hr);

            CBAltDamage = new QCheckBox(AGGroupBox);
            CBAltDamage->setText(QCheckBox::tr("Alternative damage show"));
            GBAlayout->addWidget(CBAltDamage);

            page1Layout->addWidget(AGGroupBox, 0, 1, 3, 1);
        }

        page1Layout->addWidget(new QWidget(this), 3, 0);

    }

    { // page 2
        QGridLayout * page2Layout = new QGridLayout(page2);

        {
            IconedGroupBox * gbColors = new IconedGroupBox(this);
            gbColors->setIcon(QIcon(":/res/lightbulb_on.png"));
            gbColors->setTitle(QGroupBox::tr("Custom colors"));
            page2Layout->addWidget(gbColors, 0, 0);
            QGridLayout * gbCLayout = new QGridLayout(gbColors);

            QSignalMapper * mapper = new QSignalMapper(this);

            QStandardItemModel * model = DataManager::instance().colorsModel();

            connect(model, SIGNAL(dataChanged(QModelIndex,QModelIndex)), this, SLOT(onColorModelDataChanged(QModelIndex,QModelIndex)));
            for(int i = 0; i < model->rowCount(); ++i)
            {
                QPushButton * btn = new QPushButton(this);
                btn->setSizePolicy(QSizePolicy::Minimum, QSizePolicy::Minimum);
                gbCLayout->addWidget(btn, i / 3, i % 3);
                btn->setStyleSheet(QString("background: %1").arg(model->item(i)->data().value<QColor>().name()));
                m_colorButtons.append(btn);
                connect(btn, SIGNAL(clicked()), mapper, SLOT(map()));
                mapper->setMapping(btn, i);
            }

            connect(mapper, SIGNAL(mapped(int)), this, SLOT(colorButtonClicked(int)));

            QPushButton * btn = new QPushButton(this);
            gbCLayout->addWidget(btn, (model->rowCount() - 1) / 3 + 1, 0, 1, 3);
            btn->setText(tr("Reset to default colors"));
            connect(btn, SIGNAL(clicked()), &DataManager::instance(), SLOT(resetColors()));
        }

        {
            IconedGroupBox * gbMisc = new IconedGroupBox(this);
            gbMisc->setIcon(QIcon(":/res/Settings.png"));
            gbMisc->setTitle(QGroupBox::tr("Miscellaneous"));
            page2Layout->addWidget(gbMisc, 0, 1);
            QVBoxLayout * gbCLayout = new QVBoxLayout(gbMisc);

            QHBoxLayout * GBAfpslayout = new QHBoxLayout(0);
            QLabel * maxfps = new QLabel(AGGroupBox);
            maxfps->setText(QLabel::tr("FPS limit"));
            GBAfpslayout->addWidget(maxfps);
            fpsedit = new FPSEdit(AGGroupBox);
            GBAfpslayout->addWidget(fpsedit);

            CBShowFPS = new QCheckBox(AGGroupBox);
            CBShowFPS->setText(QCheckBox::tr("Show FPS"));
            GBAfpslayout->addWidget(CBShowFPS);

            gbCLayout->addLayout(GBAfpslayout);


            WeaponTooltip = new QCheckBox(this);
            WeaponTooltip->setText(QCheckBox::tr("Show ammo menu tooltips"));
            gbCLayout->addWidget(WeaponTooltip);


            CBNameWithDate = new QCheckBox(this);
            CBNameWithDate->setText(QCheckBox::tr("Append date and time to record file name"));
            gbCLayout->addWidget(CBNameWithDate);

            BtnAssociateFiles = new QPushButton(this);
            BtnAssociateFiles->setText(QPushButton::tr("Associate file extensions"));
            BtnAssociateFiles->setVisible(!custom_data && !custom_config);
            gbCLayout->addWidget(BtnAssociateFiles);
        }

        {
            IconedGroupBox * gbProxy = new IconedGroupBox(this);
            gbProxy->setIcon(QIcon(":/res/Settings.png"));
            gbProxy->setTitle(QGroupBox::tr("Proxy settings"));
            page2Layout->addWidget(gbProxy, 1, 0);
            QGridLayout * gbLayout = new QGridLayout(gbProxy);

            QStringList sl;
            sl
                    << tr("Proxy host")
                    << tr("Proxy port")
                    << tr("Proxy login")
                    << tr("Proxy password")
                       ;
            for(int i = 0; i < sl.size(); ++i)
            {
                QLabel * l = new QLabel(gbProxy);
                l->setText(sl[i]);
                gbLayout->addWidget(l, i + 1, 0);
            }

            cbProxyType = new QComboBox(gbProxy);
            cbProxyType->addItems(QStringList()
                                  << tr("No proxy")
                                  << tr("Socks5 proxy")
                                  << tr("HTTP proxy"));
            gbLayout->addWidget(cbProxyType, 0, 1);

            leProxy = new QLineEdit(gbProxy);
            gbLayout->addWidget(leProxy, 1, 1);

            sbProxyPort = new QSpinBox(gbProxy);
            sbProxyPort->setMaximum(65535);
            gbLayout->addWidget(sbProxyPort, 2, 1);

            leProxyLogin = new QLineEdit(gbProxy);
            gbLayout->addWidget(leProxyLogin, 3, 1);

            leProxyPassword = new QLineEdit(gbProxy);
            leProxyPassword->setEchoMode(QLineEdit::Password);
            gbLayout->addWidget(leProxyPassword, 4, 1);


            connect(cbProxyType, SIGNAL(currentIndexChanged(int)), this, SLOT(onProxyTypeChanged()));
        }

        page2Layout->addWidget(new QWidget(this), 2, 0);
    }

    previousQuality = this->SLQuality->value();
    previousResolutionIndex = this->CBResolution->currentIndex();
    previousFullscreenValue = this->CBFullscreen->isChecked();

    return pageLayout;
}

QLayout * PageOptions::footerLayoutDefinition()
{
    return NULL;
}

void PageOptions::connectSignals()
{
    connect(SLQuality, SIGNAL(valueChanged(int)), this, SLOT(setQuality(int)));
    connect(CBResolution, SIGNAL(currentIndexChanged(int)), this, SLOT(setResolution(int)));
    connect(CBFullscreen, SIGNAL(stateChanged(int)), this, SLOT(setFullscreen(int)));
    connect(CBStereoMode, SIGNAL(currentIndexChanged(int)), this, SLOT(forceFullscreen(int)));
    connect(editNetNick, SIGNAL(editingFinished()), this, SLOT(trimNetNick()));
    connect(CBSavePassword, SIGNAL(stateChanged(int)), this, SLOT(savePwdChanged(int)));
}

PageOptions::PageOptions(QWidget* parent) : AbstractPage(parent)
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
        this->CBFullscreen->setEnabled(!forced);
        this->CBFullscreen->setChecked(forced ? true : previousFullscreenValue);
        this->CBResolution->setCurrentIndex(forced ? 0 : previousResolutionIndex);
    }
    else
    {
        this->SLQuality->setEnabled(true);
        this->CBFullscreen->setEnabled(true);
        this->SLQuality->setValue(previousQuality);
        this->CBFullscreen->setChecked(previousFullscreenValue);
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
    emit deleteTeamRequested(CBTeamName->currentText());
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
    bool b = cbProxyType->currentIndex() > 0;

    sbProxyPort->setEnabled(b);
    leProxy->setEnabled(b);
    leProxyLogin->setEnabled(b);
    leProxyPassword->setEnabled(b);
}
