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
#include <QLabel>
#include <QTime>

#include "pagemain.h"
#include "hwconsts.h"
#include "hwform.h"

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
    BtnSinglePlayer->setToolTip(tr("Local Game"));
    BtnSinglePlayer->setWhatsThis(tr("Play a game on a single computer"));
    pageLayout->setAlignment(BtnSinglePlayer, Qt::AlignHCenter);

    BtnNet = addButton(":/res/NetworkPlay.png", pageLayout, 2, 2, 1, 2, true);
    BtnNet->setToolTip(tr("Network Game"));
    BtnNet->setWhatsThis(tr("Play a game across a network"));
    pageLayout->setAlignment(BtnNet, Qt::AlignHCenter);

    // button order matters for overlapping (what's on top and what isn't)
    BtnInfo = addButton(":/res/HedgewarsTitle.png", pageLayout, 0, 0, 1, 4, true);
    BtnInfo->setStyleSheet("border: transparent;background: transparent;");
    //BtnInfo->setToolTip(tr("Credits")); //tooltip looks horrible with transparent background buttons
    BtnInfo->setWhatsThis(tr("Read about who is behind the Hedgewars Project"));
    pageLayout->setAlignment(BtnInfo, Qt::AlignHCenter);

    BtnFeedback = addButton("Feedback", pageLayout, 4, 0, 1, 4, false);
    BtnFeedback->setWhatsThis(tr("Leave a feedback here reporting issues, suggesting features or just saying how you like Hedgewars"));
    pageLayout->setAlignment(BtnFeedback, Qt::AlignHCenter);

    BtnDataDownload = addButton(tr("Downloadable Content"), pageLayout, 5, 0, 1, 4, false);
    //BtnDataDownload->setToolTip(tr(Downloadable Content"));
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
    BtnVideos = addButton(":/res/Record.png", bottomLayout, 1, true);
    BtnVideos->setWhatsThis(tr("Manage videos recorded from game"));
#endif

    BtnSetup = addButton(":/res/Settings.png", bottomLayout, 2, true);
    BtnSetup->setWhatsThis(tr("Edit game preferences"));

    return bottomLayout;
}

void PageMain::connectSignals()
{
    //TODO
}

PageMain::PageMain(QWidget* parent) : AbstractPage(parent)
{
    initPage();

    if(frontendEffects) setAttribute(Qt::WA_NoSystemBackground, true);
    mainNote->setOpenExternalLinks(true);

    if(!isDevBuild)
    {
        setDefautDescription(QLabel::tr("Tip: ") + randomTip());
    }
    else
    {
        setDefautDescription(QLabel::tr("This development build is 'work in progress' and may not be compatible with other versions of the game. Some features might be broken or incomplete. Use at your own risk!"));
    }

}

QString PageMain::randomTip() const
{
    QStringList Tips;
    Tips << tr("Simply pick the same color as a friend to play together as a team. Each of you will still control his or her own hedgehogs but they'll win or lose together.", "Tips");
    Tips << tr("Some weapons might do only low damage but they can be a lot more devastating in the right situation. Try to use the Desert Eagle to knock multiple hedgehogs into the water.", "Tips");
    Tips << tr("If you're unsure what to do and don't want to waste ammo, skip one round. But don't let too much time pass as there will be Sudden Death!", "Tips");
    Tips << tr("Want to save ropes? Release the rope in mid air and then shoot again. As long as you don't touch the ground you'll reuse your rope without wasting ammo!", "Tips");
    Tips << tr("If you'd like to keep others from using your preferred nickname on the official server, register an account at http://www.hedgewars.org/.", "Tips");
    Tips << tr("You're bored of default gameplay? Try one of the missions - they'll offer different gameplay depending on the one you picked.", "Tips");
    Tips << tr("By default the game will always record the last game played as a demo. Select 'Local Game' and pick the 'Demos' button on the lower right corner to play or manage them.", "Tips");
    Tips << tr("Hedgewars is Open Source and Freeware we create in our spare time. If you've got problems, ask on our forums but please don't expect 24/7 support!", "Tips");
    Tips << tr("Hedgewars is Open Source and Freeware we create in our spare time. If you like it, help us with a small donation or contribute your own work!", "Tips");
    Tips << tr("Hedgewars is Open Source and Freeware we create in our spare time. Share it with your family and friends as you like!", "Tips");
    Tips << tr("Hedgewars is Open Source and Freeware we create in our spare time. If someone sold you the game, you should try get a refund!", "Tips");
    Tips << tr("From time to time there will be official tournaments. Upcoming events will be announced at http://www.hedgewars.org/ some days in advance.", "Tips");
    Tips << tr("Hedgewars is available in many languages. If the translation in your language seems to be missing or outdated, feel free to contact us!", "Tips");
    Tips << tr("Hedgewars can be run on lots of different operating systems including Microsoft Windows, Mac OS X and Linux.", "Tips");
    Tips << tr("Always remember you're able to set up your own games in local and network/online play. You're not restricted to the 'Simple Game' option.", "Tips");
    Tips << tr("Connect one or more gamepads before starting the game to be able to assign their controls to your teams.", "Tips");
    Tips << tr("Create an account on %1 to keep others from using your most favourite nickname while playing on the official server.", "Tips").arg("<a href=\"http://www.hedgewars.org/\">http://www.hedgewars.org/</a>");
    Tips << tr("While playing you should give yourself a short break at least once an hour.", "Tips");
    Tips << tr("If your graphics card isn't able to provide hardware accelerated OpenGL, try to enable the low quality mode to improve performance.", "Tips");
    Tips << tr("If your graphics card isn't able to provide hardware accelerated OpenGL, try to update the associated drivers.", "Tips");
    Tips << tr("We're open to suggestions and constructive feedback. If you don't like something or got a great idea, let us know!", "Tips");
    Tips << tr("Especially while playing online be polite and always remember there might be some minors playing with or against you as well!", "Tips");
    Tips << tr("Special game modes such as 'Vampirism' or 'Karma' allow you to develop completely new tactics. Try them in a custom game!", "Tips");
    Tips << tr("The Windows version of Hedgewars supports Xfire. Make sure to add Hedgewars to its game list so your friends can see you playing.", "Tips");
    Tips << tr("You should never install Hedgewars on computers you don't own (school, university, work, etc.). Please ask the responsible person instead!", "Tips");
    Tips << tr("Hedgewars can be perfect for short games during breaks. Just ensure you don't add too many hedgehogs or use an huge map. Reducing time and health might help as well.", "Tips");
    Tips << tr("No hedgehogs were harmed in making this game.", "Tips");
    Tips << tr("There are three different jumps available. Tap [high jump] twice to do a very high/backwards jump.", "Tips");
    Tips << tr("Afraid of falling off a cliff? Hold down [precise] to turn [left] or [right] without actually moving.", "Tips");
    Tips << tr("Some weapons require special strategies or just lots of training, so don't give up on a particular tool if you miss an enemy once.", "Tips");
    Tips << tr("Most weapons won't work once they touch the water. The Homing Bee as well as the Cake are exceptions to this.", "Tips");
    Tips << tr("The Old Limbuger only causes a small explosion. However the wind affected smelly cloud can poison lots of hogs at once.", "Tips");
    Tips << tr("The Piano Strike is the most damaging air strike. You'll lose the hedgehog performing it, so there's a huge downside as well.", "Tips");
    Tips << tr("The Homing Bee can be tricky to use. Its turn radius depends on its velocity, so try to not use full power.", "Tips");
    Tips << tr("Sticky Mines are a perfect tool to create small chain reactions knocking enemy hedgehogs into dire situations ... or water.", "Tips");
    Tips << tr("The Hammer is most effective when used on bridges or girders. Hit hogs will just break through the ground.", "Tips");
    Tips << tr("If you're stuck behind an enemy hedgehog, use the Hammer to free yourself without getting damaged by an explosion.", "Tips");
    Tips << tr("The Cake's maximum walking distance depends on the ground it has to pass. Use [attack] to detonate it early.", "Tips");
    Tips << tr("The Flame Thrower is a weapon but it can be used for tunnel digging as well.", "Tips");
    Tips << tr("Use the Molotov or Flame Thrower to temporary keep hedgehogs from passing terrain such as tunnels or platforms.", "Tips");
    Tips << tr("Want to know who's behind the game? Click on the Hedgewars logo in the main menu to see the credits.", "Tips");
    Tips << tr("Like Hedgewars? Become a fan on %1 or follow us on %2!", "Tips").arg("<a href=\"http://www.facebook.com/Hedgewars\">Facebook</a>").arg("<a href=\"http://twitter.com/hedgewars\">Twitter</a>");
    Tips << tr("Feel free to draw your own graves, hats, flags or even maps and themes! But note that you'll have to share them somewhere to use them online.", "Tips");
    Tips << tr("Really want to wear a specific hat? Donate to us and receive an exclusive hat of your choice!", "Tips");
    // The following tip will require links to app store entries first.
    //Tips << tr("Want to play Hedgewars any time? Grab the Mobile version for %1 and %2.", "Tips").arg("").arg("");
    // the ios version is located here: http://itunes.apple.com/us/app/hedgewars/id391234866
    Tips << tr("Keep your video card drivers up to date to avoid issues playing the game.", "Tips");
    Tips << tr("You're able to associate Hedgewars related files (savegames and demo recordings) with the game to launch them right from your favorite file or internet browser.", "Tips");
#ifdef _WIN32
    Tips << tr("You can find your Hedgewars configuration files under \"My Documents\\Hedgewars\". Create backups or take the files with you, but don't edit them by hand.", "Tips");
#elif defined __APPLE__
    Tips << tr("You can find your Hedgewars configuration files under \"Library/Application Support/Hedgewars\" in your home directory. Create backups or take the files with you, but don't edit them by hand.", "Tips");
#else
    Tips << tr("You can find your Hedgewars configuration files under \".hedgewars\" in your home directory. Create backups or take the files with you, but don't edit them by hand.", "Tips");
#endif

    return Tips[QTime(0, 0, 0).secsTo(QTime::currentTime()) % Tips.length()];
}
