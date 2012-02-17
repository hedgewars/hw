/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2012 Andrey Korotaev <unC0Rr@gmail.com>
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

#include "pageoptions.h"
#include "hwconsts.h"
#include "fpsedit.h"
#include "igbox.h"

// TODO cleanup
QLayout * PageOptions::bodyLayoutDefinition()
{
    QGridLayout * pageLayout = new QGridLayout();
    pageLayout->setColumnStretch(0, 100);
    pageLayout->setColumnStretch(1, 100);
    pageLayout->setColumnStretch(2, 100);
    pageLayout->setRowStretch(0, 0);
    //pageLayout->setRowStretch(1, 100);
    pageLayout->setRowStretch(2, 0);
    pageLayout->setContentsMargins(7, 7, 7, 0);
    pageLayout->setSpacing(0);


    QGroupBox * gbTwoBoxes = new QGroupBox(this);
    pageLayout->addWidget(gbTwoBoxes, 0, 0, 1, 3);
    QGridLayout * gbTBLayout = new QGridLayout(gbTwoBoxes);
    gbTBLayout->setMargin(0);
    gbTBLayout->setSpacing(0);
    gbTBLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);

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

        gbTBLayout->addWidget(teamsBox, 0, 0);
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

        WeaponTooltip = new QCheckBox(this);
        WeaponTooltip->setText(QCheckBox::tr("Show ammo menu tooltips"));
        WeaponsLayout->addWidget(WeaponTooltip, 3, 0, 1, 4);

        gbTBLayout->addWidget(groupWeapons, 1, 0);
    }

    {
        IconedGroupBox* groupMisc = new IconedGroupBox(this);
        //groupMisc->setContentTopPadding(0);
        groupMisc->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
        groupMisc->setIcon(QIcon(":/res/miscicon.png"));
        //groupMisc->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
        groupMisc->setTitle(QGroupBox::tr("Misc"));
        QGridLayout * MiscLayout = new QGridLayout(groupMisc);

        labelNN = new QLabel(groupMisc);
        labelNN->setText(QLabel::tr("Net nick"));
        MiscLayout->addWidget(labelNN, 0, 0);

        editNetNick = new QLineEdit(groupMisc);
        editNetNick->setMaxLength(20);
        editNetNick->setText(QLineEdit::tr("unnamed"));
        connect(editNetNick, SIGNAL(editingFinished()), this, SLOT(trimNetNick()));
        MiscLayout->addWidget(editNetNick, 0, 1);

        labelNetPassword = new QLabel(groupMisc);
        labelNetPassword->setText(QLabel::tr("Password"));
        MiscLayout->addWidget(labelNetPassword, 1, 0);

        editNetPassword = new QLineEdit(groupMisc);
        editNetPassword->setEchoMode(QLineEdit::Password);
        MiscLayout->addWidget(editNetPassword, 1, 1);

        QLabel *labelLanguage = new QLabel(groupMisc);
        labelLanguage->setText(QLabel::tr("Locale") + " *");
        MiscLayout->addWidget(labelLanguage, 2, 0);

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

        MiscLayout->addWidget(CBLanguage, 2, 1);

        CBAltDamage = new QCheckBox(groupMisc);
        CBAltDamage->setText(QCheckBox::tr("Alternative damage show"));
        MiscLayout->addWidget(CBAltDamage, 3, 0, 1, 2);

        CBNameWithDate = new QCheckBox(groupMisc);
        CBNameWithDate->setText(QCheckBox::tr("Append date and time to record file name"));
        MiscLayout->addWidget(CBNameWithDate, 4, 0, 1, 2);

        BtnAssociateFiles = new QPushButton(groupMisc);
        BtnAssociateFiles->setText(QPushButton::tr("Associate file extensions"));
        BtnAssociateFiles->setEnabled(!custom_data && !custom_config);
        MiscLayout->addWidget(BtnAssociateFiles, 5, 0, 1, 2);

#ifdef __APPLE__
#ifdef SPARKLE_ENABLED
        CBAutoUpdate = new QCheckBox(groupMisc);
        CBAutoUpdate->setText(QCheckBox::tr("Check for updates at startup"));
        MiscLayout->addWidget(CBAutoUpdate, 6, 0, 1, 3);
#endif
#endif
        gbTBLayout->addWidget(groupMisc, 2, 0);
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
        GBAlayout->addWidget(CBFullscreen);

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
        connect(CBStereoMode, SIGNAL(currentIndexChanged(int)), this, SLOT(forceFullscreen(int)));

        GBAstereolayout->addWidget(CBStereoMode);
        GBAlayout->addLayout(GBAstereolayout);

        hr = new QFrame(AGGroupBox);
        hr->setFrameStyle(QFrame::HLine);
        hr->setLineWidth(3);
        hr->setFixedHeight(10);
        GBAlayout->addWidget(hr);

        QHBoxLayout * GBAvollayout = new QHBoxLayout(0);
        QLabel * vol = new QLabel(AGGroupBox);
        vol->setText(QLabel::tr("Initial sound volume"));
        GBAvollayout->addWidget(vol);
        GBAlayout->addLayout(GBAvollayout);
        volumeBox = new QSpinBox(AGGroupBox);
        volumeBox->setRange(0, 100);
        volumeBox->setSingleStep(5);
        GBAvollayout->addWidget(volumeBox);

        CBEnableSound = new QCheckBox(AGGroupBox);
        CBEnableSound->setText(QCheckBox::tr("Enable sound"));
        GBAlayout->addWidget(CBEnableSound);

        CBEnableMusic = new QCheckBox(AGGroupBox);
        CBEnableMusic->setText(QCheckBox::tr("Enable music"));
        GBAlayout->addWidget(CBEnableMusic);

        hr = new QFrame(AGGroupBox);
        hr->setFrameStyle(QFrame::HLine);
        hr->setLineWidth(3);
        hr->setFixedHeight(10);
        GBAlayout->addWidget(hr);

        QHBoxLayout * GBAfpslayout = new QHBoxLayout(0);
        QLabel * maxfps = new QLabel(AGGroupBox);
        maxfps->setText(QLabel::tr("FPS limit"));
        GBAfpslayout->addWidget(maxfps);
        GBAlayout->addLayout(GBAfpslayout);
        fpsedit = new FPSEdit(AGGroupBox);
        GBAfpslayout->addWidget(fpsedit);

        CBShowFPS = new QCheckBox(AGGroupBox);
        CBShowFPS->setText(QCheckBox::tr("Show FPS"));
        GBAlayout->addWidget(CBShowFPS);

        gbTBLayout->addWidget(AGGroupBox, 0, 1, 3, 1);
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
    connect(CBResolution, SIGNAL(currentIndexChanged(int)), this, SLOT(setResolution(int)));
    connect(CBFullscreen, SIGNAL(stateChanged(int)), this, SLOT(setFullscreen(int)));
    connect(SLQuality, SIGNAL(valueChanged(int)), this, SLOT(setQuality(int)));
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
