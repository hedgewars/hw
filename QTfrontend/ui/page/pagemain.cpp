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
#include <QLabel>
#include <QTime>
#include <QSettings>

#include "pagemain.h"
#include "hwconsts.h"
#include "hwform.h"
#include "DataManager.h"

QLayout * PageMain::bodyLayoutDefinition()
{
    QGridLayout * pageLayout = new QGridLayout();
    //pageLayout->setColumnStretch(0, 1);
    //pageLayout->setColumnStretch(1, 2);
    //pageLayout->setColumnStretch(2, 1);

    //QPushButton* btnLogo = addButton(":/res/HedgewarsTitle.png", pageLayout, 0, 0, 1, 4, true);
    //pageLayout->setAlignment(btnLogo, Qt::AlignHCenter);
    pageLayout->setRowStretch(0, 1);
    pageLayout->setRowStretch(1, 1);
    pageLayout->setRowStretch(2, 0);
    pageLayout->setRowStretch(3, 1);
    pageLayout->setRowStretch(4, 1);

    BtnSinglePlayer = addButton(":/res/LocalPlay.png", pageLayout, 2, 0, 1, 2, true);
    BtnSinglePlayer->setWhatsThis(tr("Play a game on a single computer"));
    pageLayout->setAlignment(BtnSinglePlayer, Qt::AlignHCenter);

    //BtnNet = addButton(":/res/NetworkPlay.png", (QBoxLayout*)netLayout, 1, true);
    BtnNet = addButton(":/res/NetworkPlay.png", pageLayout, 2, 2, 1, 2, true);
    BtnNet->setWhatsThis(tr("Play a game across a network"));
    pageLayout->setAlignment(BtnNet, Qt::AlignHCenter);

    originalNetworkIcon = BtnNet->icon();
    disabledNetworkIcon = QIcon(":/res/NetworkPlayDisabled.png");

    //QWidget *netLayoutWidget = new QWidget();
    QVBoxLayout *netLayout = new QVBoxLayout(BtnNet);
    //pageLayout->addWidget(netLayoutWidget, 2, 2, 1, 2);
    //netLayoutWidget->setStyleSheet("background: green;");
    //netLayoutWidget->setFixedSize(314, 260);
    netLayout->setSpacing(20);
    netLayout->setAlignment(Qt::AlignHCenter);

    BtnNetLocal = addButton(tr("Play local network game"), (QBoxLayout*)netLayout, 0, false);
    BtnNetLocal->setWhatsThis(tr("Play a game across a local area network"));
    BtnNetLocal->setFixedSize(BtnNet->width() - 50, 60);
    BtnNetLocal->setVisible(false);

    BtnNetOfficial = addButton(tr("Play official network game"), (QBoxLayout*)netLayout, 0, false);
    BtnNetOfficial->setWhatsThis(tr("Play a game on an official server"));
    BtnNetOfficial->setFixedSize(BtnNet->width() - 50, 60);
    BtnNetOfficial->setVisible(false);

    // button order matters for overlapping (what's on top and what isn't)
    BtnInfo = addButton(":/res/HedgewarsTitle.png", pageLayout, 0, 0, 1, 4, true);
    BtnInfo->setStyleSheet("border: transparent;background: transparent;");
    BtnInfo->setWhatsThis(tr("Read about who is behind the Hedgewars Project"));
    pageLayout->setAlignment(BtnInfo, Qt::AlignHCenter);

    BtnFeedback = addButton(tr("Feedback"), pageLayout, 4, 0, 1, 4, false);
    BtnFeedback->setStyleSheet("padding: 5px 10px");
    BtnFeedback->setWhatsThis(tr("Leave a feedback here reporting issues, suggesting features or just saying how you like Hedgewars"));
    pageLayout->setAlignment(BtnFeedback, Qt::AlignHCenter);

    BtnDataDownload = addButton(tr("Downloadable Content"), pageLayout, 5, 0, 1, 4, false);
    BtnDataDownload->setStyleSheet("padding: 5px 10px");
    BtnDataDownload->setWhatsThis(tr("Access the user created content downloadable from our website"));
    pageLayout->setAlignment(BtnDataDownload, Qt::AlignHCenter);

    // disable exit button sound
    btnBack->isSoundEnabled = false;

    return pageLayout;
}

QLayout * PageMain::footerLayoutDefinition()
{
    QHBoxLayout * bottomLayout = new QHBoxLayout();

    mainNote = new QLabel(this);
    mainNote->setAlignment(Qt::AlignHCenter | Qt::AlignVCenter);
    mainNote->setWordWrap(true);

    bottomLayout->addWidget(mainNote, 0);
    bottomLayout->setStretch(0,1);

    btnBack->setWhatsThis(tr("Exit game"));

#ifdef VIDEOREC
    BtnVideos = addButton(":/res/Videos.png", bottomLayout, 1, true, Qt::AlignBottom);
    BtnVideos->setWhatsThis(tr("Manage videos recorded from game"));
#endif

    BtnSetup = addButton(":/res/Settings.png", bottomLayout, 2, true, Qt::AlignBottom);
    BtnSetup->setWhatsThis(tr("Edit game preferences"));

    return bottomLayout;
}

void PageMain::connectSignals()
{
#ifndef QT_DEBUG
    connect(this, SIGNAL(pageEnter()), this, SLOT(updateTip()));
#endif
    connect(BtnNet, SIGNAL(clicked()), this, SLOT(toggleNetworkChoice()));
    //connect(BtnNetLocal, SIGNAL(clicked()), this, SLOT(toggleNetworkChoice()));
    //connect(BtnNetOfficial, SIGNAL(clicked()), this, SLOT(toggleNetworkChoice()));
    // TODO: add signal-forwarding required by (currently missing) encapsulation
}

PageMain::PageMain(QWidget* parent) : AbstractPage(parent)
{
    initPage();

    if(frontendEffects)
        setAttribute(Qt::WA_NoSystemBackground, true);
    mainNote->setOpenExternalLinks(true);
#ifdef QT_DEBUG
    setDefaultDescription(QLabel::tr("This development build is 'work in progress' and may not be compatible with other versions of the game, while some features might be broken or incomplete!"));
#else
    setDefaultDescription(QLabel::tr("Tip: %1").arg(randomTip()));
#endif
}

void PageMain::updateTip()
{
    setDefaultDescription(QLabel::tr("Tip: %1").arg(randomTip()));
}

QString PageMain::randomTip()
{
#ifdef _WIN32
    int platform = 1;
#elif defined __APPLE__
    int platform = 2;
#else
    int platform = 3;
#endif
    if(!Tips.length())
    {
        DataManager & dataMgr = DataManager::instance();

        // get locale
        QSettings settings(dataMgr.settingsFileName(),
                           QSettings::IniFormat);

        QString loc = settings.value("misc/locale", "").toString();
        if (loc.isEmpty())
            loc = QLocale::system().name();

        QString tipFile = QString("physfs://Locale/tips_" + loc + ".xml");

        // if file is non-existant try with language only
        if (!QFile::exists(tipFile))
            tipFile = QString("physfs://Locale/tips_" + loc.remove(QRegExp("_.*$")) + ".xml");

        // fallback if file for current locale is non-existant
        if (!QFile::exists(tipFile))
            tipFile = QString("physfs://Locale/tips_en.xml");

        QFile file(tipFile);
        file.open(QIODevice::ReadOnly);
        QTextStream in(&file);
        in.setCodec("UTF-8");
        QString line = in.readLine();
        int tip_platform = 0;
        while (!line.isNull()) {
            if(line.contains("<windows-only>", Qt::CaseSensitive))
                tip_platform = 1;
            if(line.contains("<mac-only>", Qt::CaseSensitive))
                tip_platform = 2;
            if(line.contains("<linux-only>", Qt::CaseSensitive))
                tip_platform = 3;
            if(line.contains("</windows-only>", Qt::CaseSensitive) ||
                    line.contains("</mac-only>", Qt::CaseSensitive) ||
                    line.contains("</linux-only>", Qt::CaseSensitive)) {
                tip_platform = 0;
            }
            QStringList split_string = line.split(QRegExp("</?tip>"));
            if((tip_platform == platform || tip_platform == 0) && split_string.size() != 1)
                Tips << split_string[1];
            line = in.readLine();
        }
        // The following tip will require links to app store entries first.
        //Tips << tr("Want to play Hedgewars any time? Grab the Mobile version for %1 and %2.", "Tips").arg("").arg("");
        // the ios version is located here: http://itunes.apple.com/us/app/hedgewars/id391234866

        file.close();
    }

    if(Tips.length())
        return Tips[QTime(0, 0, 0).secsTo(QTime::currentTime()) % Tips.length()];
    else
        return QString();
}

void PageMain::toggleNetworkChoice()
{
    bool visible = BtnNetLocal->isVisible();
    BtnNetLocal->setVisible(!visible);
    BtnNetOfficial->setVisible(!visible);
    if (visible)    BtnNet->setIcon(originalNetworkIcon);
    else            BtnNet->setIcon(disabledNetworkIcon);
}

void PageMain::resetNetworkChoice()
{
    BtnNetLocal->setVisible(false);
    BtnNetOfficial->setVisible(false);
    BtnNet->setIcon(originalNetworkIcon);
}
