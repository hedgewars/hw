/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2010 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QMessageBox>
#include <QCheckBox>
#include <QLineEdit>
#include <QDesktopWidget>
#include <QApplication>
#include <QInputDialog>

#include "gameuiconfig.h"
#include "hwform.h"
#include "pages.h"
#include "hwconsts.h"
#include "fpsedit.h"

GameUIConfig::GameUIConfig(HWForm * FormWidgets, const QString & fileName)
    : QSettings(fileName, QSettings::IniFormat)
{
    Form = FormWidgets;

    connect(Form->ui.pageOptions->CBEnableFrontendMusic, SIGNAL(toggled(bool)), Form, SLOT(Music(bool)));

    //Form->resize(value("frontend/width", 640).toUInt(), value("frontend/height", 450).toUInt());
    resizeToConfigValues();

    Form->ui.pageOptions->WeaponTooltip->setChecked(value("misc/weaponTooltips", true).toBool());

    int t = Form->ui.pageOptions->CBResolution->findText(value("video/resolution").toString());
    Form->ui.pageOptions->CBResolution->setCurrentIndex((t < 0) ? 0 : t);
    Form->ui.pageOptions->CBFullscreen->setChecked(value("video/fullscreen", false).toBool());
    bool ffscr=value("frontend/fullscreen", false).toBool();
    Form->ui.pageOptions->CBFrontendFullscreen->setChecked(ffscr);

    Form->ui.pageOptions->SLQuality->setValue(value("video/quality", 5).toUInt());
    Form->ui.pageOptions->CBStereoMode->setCurrentIndex(value("video/stereo", 0).toUInt());
    Form->ui.pageOptions->CBFrontendEffects->setChecked(frontendEffects);
    Form->ui.pageOptions->CBEnableSound->setChecked(value("audio/sound", true).toBool());
    Form->ui.pageOptions->CBEnableFrontendSound->setChecked(value("frontend/sound", true).toBool());
    Form->ui.pageOptions->CBEnableMusic->setChecked(value("audio/music", true).toBool());
    Form->ui.pageOptions->CBEnableFrontendMusic->setChecked(value("frontend/music", true).toBool());
    Form->ui.pageOptions->volumeBox->setValue(value("audio/volume", 100).toUInt());

    QString netNick = value("net/nick", "").toString();
    if (netNick.isEmpty())
        netNick = QInputDialog::getText(Form,
                QObject::tr("Nickname"),
                QObject::tr("Please enter your nickname"),
                QLineEdit::Normal,
                QDir::home().dirName());

    Form->ui.pageOptions->editNetNick->setText(netNick);

    delete netHost;
    netHost = new QString(value("net/ip", "").toString());
    netPort = value("net/port", 46631).toUInt();

    Form->ui.pageNetServer->leServerDescr->setText(value("net/servername", "hedgewars server").toString());
    Form->ui.pageNetServer->sbPort->setValue(value("net/serverport", 46631).toUInt());

    Form->ui.pageOptions->CBShowFPS->setChecked(value("fps/show", false).toBool());
    Form->ui.pageOptions->fpsedit->setValue(value("fps/limit", 27).toUInt());

    Form->ui.pageOptions->CBAltDamage->setChecked(value("misc/altdamage", false).toBool());
    Form->ui.pageOptions->CBNameWithDate->setChecked(value("misc/appendTimeToRecords", false).toBool());

#ifdef SPARKLE_ENABLED
        Form->ui.pageOptions->CBAutoUpdate->setChecked(value("misc/autoUpdate", true).toBool());
#endif

    Form->ui.pageOptions->CBLanguage->setCurrentIndex(Form->ui.pageOptions->CBLanguage->findData(value("misc/locale", "").toString()));

    depth = QApplication::desktop()->depth();
    if (depth < 16) depth = 16;
    else if (depth > 16) depth = 32;
}

QStringList GameUIConfig::GetTeamsList()
{
    QDir teamdir;
    teamdir.cd(cfgdir->absolutePath() + "/Teams");
    QStringList teamslist = teamdir.entryList(QStringList("*.hwt"),QDir::Files|QDir::Hidden);
    QStringList cleanedList;
    for (QStringList::Iterator it = teamslist.begin(); it != teamslist.end(); ++it ) {
            QString tmpTeamStr=(*it).replace(QRegExp("^(.*)\\.hwt$"), "\\1");
            cleanedList.push_back(tmpTeamStr);
    }
    return cleanedList;
}

void GameUIConfig::resizeToConfigValues()
{
        Form->resize(value("frontend/width", 800).toUInt(), value("frontend/height", 600).toUInt());
}

void GameUIConfig::SaveOptions()
{
    setValue("video/resolution", Form->ui.pageOptions->CBResolution->currentText());
    setValue("video/fullscreen", vid_Fullscreen());

    setValue("video/quality", Form->ui.pageOptions->SLQuality->value());
    setValue("video/stereo", stereoMode());

    setValue("frontend/effects", isFrontendEffects());

    setValue("misc/weaponTooltips", Form->ui.pageOptions->WeaponTooltip->isChecked());

    bool ffscr = isFrontendFullscreen();
    setValue("frontend/fullscreen", ffscr);
    emit frontendFullscreen(ffscr);
    if (!ffscr) {
      setValue("frontend/width", Form->width());
      setValue("frontend/height", Form->height());
    } else {
      //resizeToConfigValues(); // TODO: why this has been made?
    }

    setValue("audio/sound", isSoundEnabled());
    setValue("frontend/sound", isFrontendSoundEnabled());
    setValue("audio/music", isMusicEnabled());
    setValue("frontend/music", isFrontendMusicEnabled());
    setValue("audio/volume", Form->ui.pageOptions->volumeBox->value());

    setValue("net/nick", netNick());
    setValue("net/ip", *netHost);
    setValue("net/port", netPort);
    setValue("net/servername", Form->ui.pageNetServer->leServerDescr->text());
    setValue("net/serverport", Form->ui.pageNetServer->sbPort->value());

    setValue("fps/show", isShowFPSEnabled());
    setValue("fps/limit", Form->ui.pageOptions->fpsedit->value());

    setValue("misc/altdamage", isAltDamageEnabled());
    setValue("misc/appendTimeToRecords", appendDateTimeToRecordName());
    setValue("misc/locale", language());

#ifdef SPARKLE_ENABLED
        setValue("misc/autoUpdate", isAutoUpdateEnabled());
#endif
    Form->gameSettings->sync();
}

QString GameUIConfig::language()
{
    return Form->ui.pageOptions->CBLanguage->itemData(Form->ui.pageOptions->CBLanguage->currentIndex()).toString();
}

QRect GameUIConfig::vid_Resolution()
{
    QRect result(0, 0, 640, 480);
    QStringList wh = Form->ui.pageOptions->CBResolution->currentText().split('x');
    if (wh.size() == 2)
    {
        result.setWidth(wh[0].toInt());
        result.setHeight(wh[1].toInt());
    }
    return result;
}

bool GameUIConfig::vid_Fullscreen()
{
    return Form->ui.pageOptions->CBFullscreen->isChecked();
}

quint32 GameUIConfig::translateQuality()
{
    quint32 rqNone = 0x00000000;  // don't reduce quality
    //quint32 rqLowRes = 0x00000001;  // use half land array
    quint32 rqBlurryLand = 0x00000002;  // downscaled terrain
    quint32 rqNoBackground = 0x00000004;  // don't draw background
    quint32 rqSimpleRope = 0x00000008;  // avoid drawing rope
    quint32 rq2DWater = 0x00000010;  // disabe 3D water effect
    quint32 rqAntiBoom = 0x00000020;  // no fancy explosion effects
    quint32 rqKillFlakes = 0x00000040;  // no flakes
    quint32 rqSlowMenu = 0x00000080;  // ammomenu appears with no animation
    quint32 rqPlainSplash = 0x00000100;  // no droplets
    quint32 rqClampLess = 0x00000200;  // don't clamp textures
    quint32 rqTooltipsOff = 0x00000400;  // tooltips are not drawn
    quint32 rqDesyncVBlank = 0x00000800;  // don't sync on vblank
    
    quint32 result = (Form->ui.pageOptions->WeaponTooltip->isChecked()) ? rqNone : rqTooltipsOff;
    
    switch (Form->ui.pageOptions->SLQuality->value()) {
      case 5:
        break;
      case 4:
        result |= rqBlurryLand;
        break;
      case 3:
        result |= rqBlurryLand | rqKillFlakes | rqPlainSplash;
        break;
      case 2:
        result |= rqBlurryLand | rqKillFlakes | rqPlainSplash | rq2DWater |
                  rqAntiBoom | rqSlowMenu;
        break;
      case 1:
        result |= rqBlurryLand | rqKillFlakes | rqPlainSplash | rq2DWater |
                  rqAntiBoom | rqSlowMenu | rqSimpleRope | rqDesyncVBlank;
        break;
      case 0:
        result |= rqBlurryLand | rqKillFlakes | rqPlainSplash | rq2DWater |
                  rqAntiBoom | rqSlowMenu | rqSimpleRope | rqDesyncVBlank |
                  rqNoBackground | rqClampLess;
        break;
      default:
        fprintf(stderr,"unset value from slider");
        break;
    }
    
    return result;
}

bool GameUIConfig::isFrontendEffects() const
{
  return Form->ui.pageOptions->CBFrontendEffects->isChecked();
}

bool GameUIConfig::isFrontendFullscreen() const
{
  return Form->ui.pageOptions->CBFrontendFullscreen->isChecked();
}

bool GameUIConfig::isSoundEnabled()
{
    return Form->ui.pageOptions->CBEnableSound->isChecked();
}
bool GameUIConfig::isFrontendSoundEnabled()
{
    return Form->ui.pageOptions->CBEnableFrontendSound->isChecked();
}

bool GameUIConfig::isMusicEnabled()
{
    return Form->ui.pageOptions->CBEnableMusic->isChecked();
}
bool GameUIConfig::isFrontendMusicEnabled()
{
    return Form->ui.pageOptions->CBEnableFrontendMusic->isChecked();
}

bool GameUIConfig::isShowFPSEnabled()
{
    return Form->ui.pageOptions->CBShowFPS->isChecked();
}

bool GameUIConfig::isAltDamageEnabled()
{
    return Form->ui.pageOptions->CBAltDamage->isChecked();
}

quint32 GameUIConfig::stereoMode() const
{
    return Form->ui.pageOptions->CBStereoMode->currentIndex();
}

bool GameUIConfig::appendDateTimeToRecordName()
{
    return Form->ui.pageOptions->CBNameWithDate->isChecked();
}

#ifdef SPARKLE_ENABLED
bool GameUIConfig::isAutoUpdateEnabled()
{
    return Form->ui.pageOptions->CBAutoUpdate->isChecked();
}
#endif

quint8 GameUIConfig::timerInterval()
{
    return 35 - Form->ui.pageOptions->fpsedit->value();
}

quint8 GameUIConfig::bitDepth()
{
    return depth;
}

QString GameUIConfig::netNick()
{
    return Form->ui.pageOptions->editNetNick->text();
}

quint8 GameUIConfig::volume()
{
    return Form->ui.pageOptions->volumeBox->value() * 128 / 100;
}
