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

#include <QCheckBox>
#include <QLineEdit>
#include <QDesktopWidget>
#include <QInputDialog>
#include <QCryptographicHash>
#include <QStandardItemModel>
#include <QNetworkProxy>
#include <QNetworkProxyFactory>
#include <utility>
#include <QVariant>

#include "gameuiconfig.h"
#include "hwform.h"
#include "pageoptions.h"
#include "pagevideos.h"
#include "pagenetserver.h"
#include "hwconsts.h"
#include "fpsedit.h"
#include "HWApplication.h"
#include "DataManager.h"
#include "SDL.h"


const QNetworkProxy::ProxyType proxyTypesMap[] = {
    QNetworkProxy::NoProxy
    , QNetworkProxy::NoProxy // dummy value
    , QNetworkProxy::Socks5Proxy
    , QNetworkProxy::HttpProxy};


GameUIConfig::GameUIConfig(HWForm * FormWidgets, const QString & fileName)
    : QSettings(fileName, QSettings::IniFormat, FormWidgets)
{
    Form = FormWidgets;

    setIniCodec("UTF-8");

    connect(Form->ui.pageOptions->CBFrontendMusic, SIGNAL(toggled(bool)), Form, SLOT(Music(bool)));

    for(int i = 0; i < BINDS_NUMBER; i++)
    {
        m_binds.append(BindAction());
        m_binds[i].action = cbinds[i].action;
        m_binds[i].strbind = cbinds[i].strbind;
    }

    //Form->resize(value("frontend/width", 640).toUInt(), value("frontend/height", 450).toUInt());
    resizeToConfigValues();

    reloadValues();
#ifdef VIDEOREC
    reloadVideosValues();
#endif
}

void GameUIConfig::reloadValues(void)
{
    Form->ui.pageOptions->WeaponTooltip->setChecked(value("misc/weaponTooltips", true).toBool());

    int t = Form->ui.pageOptions->CBResolution->findText(value("video/fullscreenResolution").toString());
    if (t < 0)
    {
        if (Form->ui.pageOptions->CBResolution->count() > 1)
            Form->ui.pageOptions->CBResolution->setCurrentIndex(1);
        else
            Form->ui.pageOptions->CBResolution->setCurrentIndex(0);
    }
    else Form->ui.pageOptions->CBResolution->setCurrentIndex(t);

    // Default the windowed resolution to 5/6 of the screen size
    QSize screenSize = SDLInteraction::instance().getCurrentResolution();
    screenSize *= 5.0 / 6;

    QString widthStr = QString::number(screenSize.width());
    QString heightStr = QString::number(screenSize.height());
    QString wWidth = value("video/windowedWidth", widthStr).toString();
    QString wHeight = value("video/windowedHeight", heightStr).toString();
    // If left blank reset the resolution to the default
    wWidth = (wWidth == "" ? widthStr : wWidth);
    wHeight = (wHeight == "" ? heightStr : wHeight);
    Form->ui.pageOptions->windowWidthEdit->setValue(wWidth.toInt());
    Form->ui.pageOptions->windowHeightEdit->setValue(wHeight.toInt());

    Form->ui.pageOptions->CBResolution->setCurrentIndex((t < 0) ? 1 : t);
    Form->ui.pageOptions->CBFullscreen->setChecked(value("video/fullscreen", false).toBool());
    bool ffscr=value("frontend/fullscreen", false).toBool();
    Form->ui.pageOptions->CBFrontendFullscreen->setChecked(ffscr);

    Form->ui.pageOptions->SLQuality->setValue(value("video/quality", 5).toUInt());
    Form->ui.pageOptions->CBStereoMode->setCurrentIndex(value("video/stereo", 0).toUInt());
    Form->ui.pageOptions->CBFrontendEffects->setChecked(value("frontend/effects", true).toBool());
    Form->ui.pageOptions->CBSound->setChecked(value("audio/sound", true).toBool());
    Form->ui.pageOptions->CBFrontendSound->setChecked(value("frontend/sound", true).toBool());
    Form->ui.pageOptions->CBMusic->setChecked(value("audio/music", true).toBool());
    Form->ui.pageOptions->CBFrontendMusic->setChecked(value("frontend/music", true).toBool());
    Form->ui.pageOptions->CBDampenAudio->setChecked(value("audio/dampen", true).toBool());
    Form->ui.pageOptions->SLVolume->setValue(value("audio/volume", 100).toUInt());

    QString netNick = value("net/nick", tr("Guest")+QString("%1").arg(rand())).toString();
    Form->ui.pageOptions->editNetNick->setText(netNick);
    bool savePwd = value("net/savepassword",true).toBool();
    Form->ui.pageOptions->CBSavePassword->setChecked(savePwd);

    Form->ui.pageOptions->editNetPassword->installEventFilter(this);

    int passLength = value("net/passwordlength", 0).toInt();
    if (!savePwd) {
        Form->ui.pageOptions->editNetPassword->setEnabled(false);
        Form->ui.pageOptions->editNetPassword->setText("");
        setNetPasswordLength(0);
    } else
    {
        setNetPasswordLength(passLength);
    }

    delete netHost;
    netHost = new QString(value("net/ip", "").toString());
    netPort = value("net/port", NETGAME_DEFAULT_PORT).toUInt();

    Form->ui.pageNetServer->leServerDescr->setText(value("net/servername", "Hedgewars Server").toString());
    Form->ui.pageNetServer->sbPort->setValue(value("net/serverport", NETGAME_DEFAULT_PORT).toUInt());

    Form->ui.pageOptions->CBShowFPS->setChecked(value("fps/show", false).toBool());
    Form->ui.pageOptions->fpsedit->setValue(value("fps/limit", 27).toUInt());

    Form->ui.pageOptions->CBAltDamage->setChecked(value("misc/altdamage", true).toBool());
    Form->ui.pageOptions->CBNameWithDate->setChecked(value("misc/appendTimeToRecords", false).toBool());

    Form->ui.pageOptions->CBTeamTag->setChecked(value("misc/teamtag", true).toBool());
    Form->ui.pageOptions->CBHogTag->setChecked(value("misc/hogtag", true).toBool());
    Form->ui.pageOptions->CBHealthTag->setChecked(value("misc/healthtag", true).toBool());
    Form->ui.pageOptions->CBTagOpacity->setChecked(value("misc/tagopacity", false).toBool());

#ifdef SPARKLE_ENABLED
    Form->ui.pageOptions->CBAutoUpdate->setChecked(value("misc/autoUpdate", true).toBool());
#endif

    Form->ui.pageOptions->CBLanguage->setCurrentIndex(Form->ui.pageOptions->CBLanguage->findData(value("misc/locale", "").toString()));

    Form->ui.pageOptions->cbProxyType->setCurrentIndex(value("proxy/type", 0).toInt());
    Form->ui.pageOptions->leProxy->setText(value("proxy/host", "").toString());
    Form->ui.pageOptions->sbProxyPort->setValue(value("proxy/port", "8080").toInt());
    Form->ui.pageOptions->leProxyLogin->setText(value("proxy/login", "").toString());
    Form->ui.pageOptions->leProxyPassword->setText(value("proxy/password", "").toString());

    applyProxySettings();

    { // load colors
        QStandardItemModel * model = DataManager::instance().colorsModel();
        for(int i = model->rowCount() - 1; i >= 0; --i)
            model->item(i)->setData(QColor(value(QString("colors/color%1").arg(i), model->item(i)->data()).toString()));
    }

    { // load binds
        for(int i = 0; i < BINDS_NUMBER; i++)
        {
            m_binds[i].strbind = value(QString("Binds/%1").arg(m_binds[i].action), cbinds[i].strbind).toString();
            if (m_binds[i].strbind.isEmpty() || m_binds[i].strbind == "default") m_binds[i].strbind = cbinds[i].strbind;
        }
    }
}

void GameUIConfig::reloadVideosValues(void)
{
    // one pass with default values
    Form->ui.pageOptions->setDefaultOptions();

    // then load user configuration
    int framerateBoxIndex = Form->ui.pageOptions->framerateBox->findData(value("videorec/framerate", rec_Framerate()).toUInt());
    if(framerateBoxIndex != -1)
        Form->ui.pageOptions->framerateBox->setCurrentIndex(framerateBoxIndex);
    Form->ui.pageOptions->bitrateBox->setValue(value("videorec/bitrate", rec_Bitrate()).toUInt());
    bool useGameRes = value("videorec/usegameres",Form->ui.pageOptions->checkUseGameRes->isChecked()).toBool();
    if (useGameRes)
    {
        QRect res = vid_Resolution();
        Form->ui.pageOptions->widthEdit->setText(QString::number(res.width()));
        Form->ui.pageOptions->heightEdit->setText(QString::number(res.height()));
    }
    else
    {
        Form->ui.pageOptions->widthEdit->setText(value("videorec/width","800").toString());
        Form->ui.pageOptions->heightEdit->setText(value("videorec/height","600").toString());
    }
    Form->ui.pageOptions->checkUseGameRes->setChecked(useGameRes);
    Form->ui.pageOptions->checkRecordAudio->setChecked(
            value("videorec/audio",Form->ui.pageOptions->checkRecordAudio->isChecked()).toBool() );
    if (!Form->ui.pageOptions->tryCodecs(value("videorec/format","no").toString(),
                                        value("videorec/videocodec","no").toString(),
                                        value("videorec/audiocodec","no").toString()))
        Form->ui.pageOptions->setDefaultCodecs();
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
    // fill 2/3 of the screen desktop
    const QRect deskSize = HWApplication::desktop()->screenGeometry(-1);
    Form->resize(value("frontend/width", qMin(qMax(deskSize.width()*2/3,800),deskSize.width())).toUInt(),
                 value("frontend/height", qMin(qMax(deskSize.height()*2/3,600),deskSize.height())).toUInt());

    // move the window to the center of the screen
    QPoint center = HWApplication::desktop()->availableGeometry(-1).center();
    center.setX(center.x() - (Form->width()/2));
    center.setY(center.y() - (Form->height()/2));
    Form->move(center);
}

void GameUIConfig::SaveOptions()
{
    setValue("video/fullscreenResolution", Form->ui.pageOptions->CBResolution->currentText());
    setValue("video/windowedWidth", Form->ui.pageOptions->windowWidthEdit->value());
    setValue("video/windowedHeight", Form->ui.pageOptions->windowHeightEdit->value());
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
    setValue("audio/volume", Form->ui.pageOptions->SLVolume->value());
    setValue("audio/dampen", isAudioDampenEnabled());

    setValue("net/nick", netNick());
    if (netPasswordIsValid() && Form->ui.pageOptions->CBSavePassword->isChecked()) {
        setPasswordHash(netPasswordHash());
    }
    else if(!Form->ui.pageOptions->CBSavePassword->isChecked()) {
        clearPasswordHash();
    }

    setValue("net/savepassword", Form->ui.pageOptions->CBSavePassword->isChecked());
    setValue("net/ip", *netHost);
    setValue("net/port", netPort);
    setValue("net/servername", Form->ui.pageNetServer->leServerDescr->text());
    setValue("net/serverport", Form->ui.pageNetServer->sbPort->value());

    setValue("fps/show", isShowFPSEnabled());
    setValue("fps/limit", Form->ui.pageOptions->fpsedit->value());

    setValue("misc/altdamage", isAltDamageEnabled());

    setValue("misc/teamtag",   Form->ui.pageOptions->CBTeamTag->isChecked());
    setValue("misc/hogtag",    Form->ui.pageOptions->CBHogTag->isChecked());
    setValue("misc/healthtag", Form->ui.pageOptions->CBHealthTag->isChecked());
    setValue("misc/tagopacity",Form->ui.pageOptions->CBTagOpacity->isChecked());

    setValue("misc/appendTimeToRecords", appendDateTimeToRecordName());
    setValue("misc/locale", language());

#ifdef SPARKLE_ENABLED
    setValue("misc/autoUpdate", isAutoUpdateEnabled());
#endif

    { // setup proxy
        int proxyType = Form->ui.pageOptions->cbProxyType->currentIndex();
        setValue("proxy/type", proxyType);

        if(proxyType == PageOptions::Socks5Proxy || proxyType == PageOptions::HTTPProxy)
        {
            setValue("proxy/host", Form->ui.pageOptions->leProxy->text());
            setValue("proxy/port", Form->ui.pageOptions->sbProxyPort->value());
            setValue("proxy/login", Form->ui.pageOptions->leProxyLogin->text());
            setValue("proxy/password", Form->ui.pageOptions->leProxyPassword->text());
        }

        applyProxySettings();
    }

    { // save colors
        QStandardItemModel * model = DataManager::instance().colorsModel();
        for(int i = model->rowCount() - 1; i >= 0; --i)
            setValue(QString("colors/color%1").arg(i), model->item(i)->data().value<QColor>().name());
    }

    sync();
}

void GameUIConfig::SaveVideosOptions()
{
    QRect res = rec_Resolution();
    setValue("videorec/format", AVFormat());
    setValue("videorec/videocodec", videoCodec());
    setValue("videorec/audiocodec", audioCodec());
    setValue("videorec/framerate", rec_Framerate());
    setValue("videorec/bitrate", rec_Bitrate());
    setValue("videorec/width", res.width());
    setValue("videorec/height", res.height());
    setValue("videorec/usegameres", Form->ui.pageOptions->checkUseGameRes->isChecked());
    setValue("videorec/audio", recordAudio());

    sync();
}

void GameUIConfig::setValue(const QString &key, const QVariant &value)
{
    //qDebug() << "[settings]" << key << value;
    QSettings::setValue(key, value);
}

QString GameUIConfig::language()
{
    return Form->ui.pageOptions->CBLanguage->itemData(Form->ui.pageOptions->CBLanguage->currentIndex()).toString();
}

std::pair<QRect, QRect> GameUIConfig::vid_ResolutionPair() {
    // returns a pair of both the fullscreen and the windowed resolution
    QRect full(0, 0, 640, 480);
    QRect windowed(0, 0, 640, 480);
    QStringList wh = Form->ui.pageOptions->CBResolution->currentText().split('x');
    if (wh.size() == 2)
    {
        full.setWidth(wh[0].toInt());
        full.setHeight(wh[1].toInt());
    }
    windowed.setWidth(Form->ui.pageOptions->windowWidthEdit->value());
    windowed.setHeight(Form->ui.pageOptions->windowHeightEdit->value());
    return std::make_pair(full, windowed);
}

QRect GameUIConfig::vid_Resolution()
{
    std::pair<QRect, QRect> result = vid_ResolutionPair();
    if(Form->ui.pageOptions->CBFullscreen->isChecked())
        return result.first;
    else
        return result.second;
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

bool GameUIConfig::isHolidaySillinessEnabled() const
{
    return value("misc/holidaySilliness", true).toBool();
}

bool GameUIConfig::isSoundEnabled()
{
    return Form->ui.pageOptions->CBSound->isChecked();
}
bool GameUIConfig::isFrontendSoundEnabled()
{
    return Form->ui.pageOptions->CBFrontendSound->isChecked();
}

bool GameUIConfig::isMusicEnabled()
{
    return Form->ui.pageOptions->CBMusic->isChecked();
}
bool GameUIConfig::isFrontendMusicEnabled()
{
    return Form->ui.pageOptions->CBFrontendMusic->isChecked();
}
bool GameUIConfig::isAudioDampenEnabled()
{
    return Form->ui.pageOptions->CBDampenAudio->isChecked();
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
    return (netPasswordLength() == 0 || Form->ui.pageOptions->editNetPassword->text() != QString(netPasswordLength(), '*'));
}

void GameUIConfig::clearPasswordHash()
{
    setValue("net/passwordhash", QString());
    setValue("net/passwordlength", 0);
    setValue("net/savepassword", false); //changes the savepassword value to false in order to not let the user save an empty password in PAGE_SETUP
    Form->ui.pageOptions->editNetPassword->setEnabled(false);
    Form->ui.pageOptions->editNetPassword->setText("");
}

void GameUIConfig::setPasswordHash(const QString & passwordhash)
{
    setValue("net/passwordhash", passwordhash);
    if (passwordhash!=NULL && passwordhash.size() > 0)
    {
    // WTF - the whole point of "password length" was to have the dots match what they typed.  This is totally pointless, and all hashes are the same length for a given hash so might as well hardcode it.
    // setValue("net/passwordlength", passwordhash.size()/4);
        setValue("net/passwordlength", 8);

    // More WTF
    //setNetPasswordLength(passwordhash.size()/4);  //the hash.size() is divided by 4 let PAGE_SETUP use a reasonable number of stars to display the PW
        setNetPasswordLength(8);
    }
    else
    {
        setValue("net/passwordlength", 0);
        setNetPasswordLength(0);
    }
}

QString GameUIConfig::passwordHash()
{
    return value("net/passwordhash").toString();
}

void GameUIConfig::clearTempHash()
{
    setTempHash(QString());
}

void GameUIConfig::setTempHash(const QString & temphash)
{
    this->temphash = temphash;
}

QString GameUIConfig::tempHash() {
    return this->temphash;
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
        Form->ui.pageOptions->editNetPassword->setText(QString(passwordLength, '*'));
    }
    else
    {
        Form->ui.pageOptions->editNetPassword->setText("");
    }
}

quint8 GameUIConfig::volume()
{
    return Form->ui.pageOptions->SLVolume->value() * 128 / 100;
}

QString GameUIConfig::AVFormat()
{
    return Form->ui.pageOptions->format();
}

QString GameUIConfig::videoCodec()
{
    return Form->ui.pageOptions->videoCodec();
}

QString GameUIConfig::audioCodec()
{
    return Form->ui.pageOptions->audioCodec();
}

QRect GameUIConfig::rec_Resolution()
{
    if (Form->ui.pageOptions->checkUseGameRes->isChecked())
        return vid_Resolution();
    QRect res(0,0,0,0);
    res.setWidth(Form->ui.pageOptions->widthEdit->text().toUInt());
    res.setHeight(Form->ui.pageOptions->heightEdit->text().toUInt());
    return res;
}

int GameUIConfig::rec_Framerate()
{
    return Form->ui.pageOptions->framerateBox->itemData(Form->ui.pageOptions->framerateBox->currentIndex()).toInt();
}

int GameUIConfig::rec_Bitrate()
{
    return Form->ui.pageOptions->bitrateBox->value();
}

bool GameUIConfig::recordAudio()
{
    return Form->ui.pageOptions->checkRecordAudio->isChecked();
}

// Gets a bind for a bindID
QString GameUIConfig::bind(int bindID)
{
    return m_binds[bindID].strbind;
}

// Sets a bind for a bindID and saves it
void GameUIConfig::setBind(int bindID, QString & strbind)
{
    m_binds[bindID].strbind = strbind;
    setValue(QString("Binds/%1").arg(m_binds[bindID].action), strbind);
}

void GameUIConfig::applyProxySettings()
{
    QNetworkProxy proxy;

    int proxyType = Form->ui.pageOptions->cbProxyType->currentIndex();

    if(proxyType == PageOptions::SystemProxy)
    {
        // use system proxy settings
        proxy = QNetworkProxyFactory::systemProxyForQuery().at(0);
    } else
    {
        proxy.setType(proxyTypesMap[proxyType]);
        proxy.setHostName(Form->ui.pageOptions->leProxy->text());
        proxy.setPort(Form->ui.pageOptions->sbProxyPort->value());
        proxy.setUser(Form->ui.pageOptions->leProxyLogin->text());
        proxy.setPassword(Form->ui.pageOptions->leProxyPassword->text());
    }

    QNetworkProxy::setApplicationProxy(proxy);
}
