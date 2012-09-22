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

#include <QMessageBox>
#include <QCheckBox>
#include <QLineEdit>
#include <QDesktopWidget>
#include <QInputDialog>
#include <QCryptographicHash>
#include <QStandardItemModel>
#include <QNetworkProxy>
#include <QNetworkProxyFactory>

#include "gameuiconfig.h"
#include "hwform.h"
#include "pageoptions.h"
#include "pagevideos.h"
#include "pagenetserver.h"
#include "hwconsts.h"
#include "fpsedit.h"
#include "HWApplication.h"
#include "DataManager.h"

GameUIConfig::GameUIConfig(HWForm * FormWidgets, const QString & fileName)
    : QSettings(fileName, QSettings::IniFormat)
{
    Form = FormWidgets;

    connect(Form->ui.pageOptions->CBEnableFrontendMusic, SIGNAL(toggled(bool)), Form, SLOT(Music(bool)));

    //Form->resize(value("frontend/width", 640).toUInt(), value("frontend/height", 450).toUInt());
    resizeToConfigValues();

    reloadValues();
    reloadVideosValues();
}

void GameUIConfig::reloadValues(void)
{
    Form->ui.pageOptions->WeaponTooltip->setChecked(value("misc/weaponTooltips", true).toBool());

    int t = Form->ui.pageOptions->CBResolution->findText(value("video/resolution").toString());
    if (t < 0)
    {
        if (Form->ui.pageOptions->CBResolution->count() > 1)
            Form->ui.pageOptions->CBResolution->setCurrentIndex(1);
        else
            Form->ui.pageOptions->CBResolution->setCurrentIndex(0);
    }
    else Form->ui.pageOptions->CBResolution->setCurrentIndex(t);
    Form->ui.pageOptions->CBResolution->setCurrentIndex((t < 0) ? 1 : t);
    Form->ui.pageOptions->CBFullscreen->setChecked(value("video/fullscreen", false).toBool());
    bool ffscr=value("frontend/fullscreen", false).toBool();
    Form->ui.pageOptions->CBFrontendFullscreen->setChecked(ffscr);

    Form->ui.pageOptions->SLQuality->setValue(value("video/quality", 5).toUInt());
    Form->ui.pageOptions->CBStereoMode->setCurrentIndex(value("video/stereo", 0).toUInt());
    Form->ui.pageOptions->CBEnableFrontendSound->setChecked(value("frontend/effects", true).toBool());
    Form->ui.pageOptions->CBEnableSound->setChecked(value("audio/sound", true).toBool());
    Form->ui.pageOptions->CBEnableFrontendSound->setChecked(value("frontend/sound", true).toBool());
    Form->ui.pageOptions->CBEnableMusic->setChecked(value("audio/music", true).toBool());
    Form->ui.pageOptions->CBEnableFrontendMusic->setChecked(value("frontend/music", true).toBool());
    Form->ui.pageOptions->volumeBox->setValue(value("audio/volume", 100).toUInt());

    QString netNick = value("net/nick", "").toString();
    Form->ui.pageOptions->editNetNick->setText(netNick);
    bool savePwd = value("net/savepassword",true).toBool();
    Form->ui.pageOptions->CBSavePassword->setChecked(savePwd);

    Form->ui.pageOptions->editNetPassword->installEventFilter(this);

    int passLength = value("net/passwordlength", 0).toInt();
    setNetPasswordLength(passLength);
    if (savePwd == false) {
        Form->ui.pageOptions->editNetPassword->setEnabled(savePwd);
        Form->ui.pageOptions->editNetPassword->setText("");
        setNetPasswordLength(0);        
    }

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

    Form->ui.pageOptions->cbProxyType->setCurrentIndex(value("proxy/type", 0).toInt());
    Form->ui.pageOptions->leProxy->setText(value("proxy/host", "").toString());
    Form->ui.pageOptions->sbProxyPort->setValue(value("proxy/port", "8080").toInt());
    Form->ui.pageOptions->leProxyLogin->setText(value("proxy/login", "").toString());
    Form->ui.pageOptions->leProxyPassword->setText(value("proxy/password", "").toString());

    depth = HWApplication::desktop()->depth();
    if (depth < 16) depth = 16;
    else if (depth > 16) depth = 32;

    { // load colors
        QStandardItemModel * model = DataManager::instance().colorsModel();
        for(int i = model->rowCount() - 1; i >= 0; --i)
            model->item(i)->setData(QColor(value(QString("colors/color%1").arg(i), model->item(i)->data().value<QColor>()).value<QColor>()));
    }
}

void GameUIConfig::reloadVideosValues(void)
{
    Form->ui.pageVideos->framerateBox->setValue(value("videorec/fps",25).toUInt());
    Form->ui.pageVideos->bitrateBox->setValue(value("videorec/bitrate",400).toUInt());
    bool useGameRes = value("videorec/usegameres",true).toBool();
    if (useGameRes)
    {
        QRect res = vid_Resolution();
        Form->ui.pageVideos->widthEdit->setText(QString::number(res.width()));
        Form->ui.pageVideos->heightEdit->setText(QString::number(res.height()));
    }
    else
    {
        Form->ui.pageVideos->widthEdit->setText(value("videorec/width","800").toString());
        Form->ui.pageVideos->heightEdit->setText(value("videorec/height","600").toString());
    }
    Form->ui.pageVideos->checkUseGameRes->setChecked(useGameRes);
    Form->ui.pageVideos->checkRecordAudio->setChecked(value("videorec/audio",true).toBool());
    if (!Form->ui.pageVideos->tryCodecs(value("videorec/format","no").toString(),
                                        value("videorec/videocodec","no").toString(),
                                        value("videorec/audiocodec","no").toString()))
        Form->ui.pageVideos->setDefaultCodecs();
}

QStringList GameUIConfig::GetTeamsList()
{
    QDir teamdir;
    teamdir.cd(cfgdir->absolutePath() + "/Teams");
    QStringList teamslist = teamdir.entryList(QStringList("*.hwt"),QDir::Files|QDir::Hidden);
    QStringList cleanedList;
    for (QStringList::Iterator it = teamslist.begin(); it != teamslist.end(); ++it )
    {
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
    if (!ffscr)
    {
        setValue("frontend/width", Form->width());
        setValue("frontend/height", Form->height());
    }
    else
    {
        //resizeToConfigValues(); // TODO: why this has been made?
    }

    setValue("audio/sound", isSoundEnabled());
    setValue("frontend/sound", isFrontendSoundEnabled());
    setValue("audio/music", isMusicEnabled());
    setValue("frontend/music", isFrontendMusicEnabled());
    setValue("audio/volume", Form->ui.pageOptions->volumeBox->value());

    setValue("net/nick", netNick());
    if (netPasswordIsValid() && Form->ui.pageOptions->CBSavePassword->isChecked())
    {
        setValue("net/passwordhash", netPasswordHash());
        setValue("net/passwordlength", netPasswordLength());
    }
    setValue("net/savepassword", Form->ui.pageOptions->CBSavePassword->isChecked());
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

    { // setup proxy
        int proxyType = Form->ui.pageOptions->cbProxyType->currentIndex();
        setValue("proxy/type", proxyType);

        if(proxyType > 1)
        {
            setValue("proxy/host", Form->ui.pageOptions->leProxy->text());
            setValue("proxy/port", Form->ui.pageOptions->sbProxyPort->value());
            setValue("proxy/login", Form->ui.pageOptions->leProxyLogin->text());
            setValue("proxy/password", Form->ui.pageOptions->leProxyPassword->text());
        }

        QNetworkProxy proxy;

        if(proxyType == 1)
        {
            // use system proxy settings
            proxy = QNetworkProxyFactory::systemProxyForQuery().at(0);
        } else
        {
            const QNetworkProxy::ProxyType proxyTypesMap[] = {
                QNetworkProxy::NoProxy
                , QNetworkProxy::NoProxy // dummy value
                , QNetworkProxy::Socks5Proxy
                , QNetworkProxy::HttpProxy};

            proxy.setType(proxyTypesMap[proxyType]);
            proxy.setHostName(Form->ui.pageOptions->leProxy->text());
            proxy.setPort(Form->ui.pageOptions->sbProxyPort->value());
            proxy.setUser(Form->ui.pageOptions->leProxyLogin->text());
            proxy.setPassword(Form->ui.pageOptions->leProxyPassword->text());
        }

        QNetworkProxy::setApplicationProxy(proxy);
    }

    { // save colors
        QStandardItemModel * model = DataManager::instance().colorsModel();
        for(int i = model->rowCount() - 1; i >= 0; --i)
            setValue(QString("colors/color%1").arg(i), model->item(i)->data());
    }

    Form->gameSettings->sync();
}

void GameUIConfig::SaveVideosOptions()
{
    QRect res = rec_Resolution();
    setValue("videorec/format", AVFormat());
    setValue("videorec/videocodec", videoCodec());
    setValue("videorec/audiocodec", audioCodec());
    setValue("videorec/fps", rec_Framerate());
    setValue("videorec/bitrate", rec_Bitrate());
    setValue("videorec/width", res.width());
    setValue("videorec/height", res.height());
    setValue("videorec/usegameres", Form->ui.pageVideos->checkUseGameRes->isChecked());
    setValue("videorec/audio", recordAudio());

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

    switch (Form->ui.pageOptions->SLQuality->value())
    {
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

void GameUIConfig::updNetNick()
{
    Form->ui.pageOptions->editNetNick->setText(value("net/nick", "").toString());
}

QByteArray GameUIConfig::netPasswordHash()
{
    return QCryptographicHash::hash(Form->ui.pageOptions->editNetPassword->text().toUtf8(), QCryptographicHash::Md5).toHex();
}

int GameUIConfig::netPasswordLength()
{
    return Form->ui.pageOptions->editNetPassword->text().size();
}

bool GameUIConfig::netPasswordIsValid()
{
    return (netPasswordLength() == 0 || Form->ui.pageOptions->editNetPassword->text() != QString(netPasswordLength(), '\0'));
}

// When hedgewars launches, the password field is set with null characters. If the user tries to edit the field and there are such characters, then clear the field
bool GameUIConfig::eventFilter(QObject *object, QEvent *event)
{
    if (event->type() == QEvent::FocusIn)
    {
        if ((QLineEdit *)object == Form->ui.pageOptions->editNetPassword)
        {
            if (!netPasswordIsValid())
            {
                Form->ui.pageOptions->editNetPassword->clear();
            }
        }
    }

    // Don't filter anything
    return false;
}

void GameUIConfig::setNetPasswordLength(int passwordLength)
{
    if (passwordLength > 0)
    {
        Form->ui.pageOptions->editNetPassword->setText(QString(passwordLength, '\0'));
    }
    else
    {
        Form->ui.pageOptions->editNetPassword->setText("");
    }
}

quint8 GameUIConfig::volume()
{
    return Form->ui.pageOptions->volumeBox->value() * 128 / 100;
}

QString GameUIConfig::AVFormat()
{
    return Form->ui.pageVideos->format();
}

QString GameUIConfig::videoCodec()
{
    return Form->ui.pageVideos->videoCodec();
}

QString GameUIConfig::audioCodec()
{
    return Form->ui.pageVideos->audioCodec();
}

QRect GameUIConfig::rec_Resolution()
{
    if (Form->ui.pageVideos->checkUseGameRes->isChecked())
        return vid_Resolution();
    QRect res(0,0,0,0);
    res.setWidth(Form->ui.pageVideos->widthEdit->text().toUInt());
    res.setHeight(Form->ui.pageVideos->heightEdit->text().toUInt());
    return res;
}

int GameUIConfig::rec_Framerate()
{
    return Form->ui.pageVideos->framerateBox->value();
}

int GameUIConfig::rec_Bitrate()
{
    return Form->ui.pageVideos->bitrateBox->value();
}

bool GameUIConfig::recordAudio()
{
    return Form->ui.pageVideos->checkRecordAudio->isChecked();
}
