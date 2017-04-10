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
#include <QLabel>
#include <QList>
#include <QUrl>
#include <QRegExp>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QMessageBox>
#include <QNetworkReply>
#include <QDebug>
#include "hwconsts.h"
#include "SDLInteraction.h"
#include "SDL.h"
#include "SDL_version.h"
#include "physfs.h"

#ifdef VIDEOREC
extern "C"
{
    #include "libavcodec/version.h"
    #include "libavformat/version.h"
    #include "libavutil/avutil.h" // version.h only from 51.36.0
}
#endif


#if defined(Q_OS_WINDOWS)
#define sopath(x) x ".dll"
#elif defined(Q_OS_MAC)
#define sopath(x) "@executable_path/../Frameworks/" x ".framework/" x
#else
#define sopath(x) "lib" x ".so"
#endif

#include "about.h"

About::About(QWidget * parent) :
    QWidget(parent)
{
    QGridLayout *mainLayout = new QGridLayout(this);

    QVBoxLayout * leftLayout = new QVBoxLayout();
    mainLayout->addLayout(leftLayout, 0, 0, 2, 1);

    QLabel *imageLabel = new QLabel;
    QImage image(":/res/Hedgehog.png");
    imageLabel->setPixmap(QPixmap::fromImage(image));
    imageLabel->setFixedWidth(273);
    imageLabel->setFixedHeight(300);

    leftLayout->addWidget(imageLabel, 0, Qt::AlignHCenter);

    QLabel *lbl1 = new QLabel(this);
    lbl1->setOpenExternalLinks(true);
    lbl1->setText(
        "<style type=\"text/css\">"
        "a { color: #ffcc00; }"
//            "a:hover { color: yellow; }"
        "</style>"
        "<div align=\"center\"><h1>Hedgewars " + *cVersionString + "</h1>"
        "<h3>" + QLabel::tr("Revision") + " " + *cRevisionString + " (" + *cHashString + ")</h3>"
        "<p><a href=\"https://www.hedgewars.org/\">https://www.hedgewars.org/</a></p>" +
        QLabel::tr("This program is distributed under the %1").arg("<a \
        href=\"http://www.gnu.org/licenses/gpl-2.0.html\">GNU GPL v2</a>") +
        "</div>"
    );
    lbl1->setWordWrap(true);
    mainLayout->addWidget(lbl1, 0, 1);

    lbl2 = new QTextBrowser(this);
    lbl2->setOpenExternalLinks(true);
    QUrl localpage = QUrl::fromLocalFile(":/res/html/about.html");
    lbl2->setSource(localpage); //sets the source of the label from the file above
    mainLayout->addWidget(lbl2, 1, 1);

    /* Library information */

    QString libinfo = "<style type=text/css>a:link { color: #FFFF6E; }</style>";
    libinfo.append(QString(tr("Dependency versions:") + QString("<br>")));

#ifdef __GNUC__
    libinfo.append(QString(tr("<a href=\"http://gcc.gnu.org\">GCC</a>: %1")).arg(__VERSION__));
    libinfo.append(QString("<br>"));
#else
    libinfo.append(QString(tr("Unknown Compiler")).arg(__VERSION__) + QString("<br>"));
#endif

    const SDL_version *sdl_ver;
    SDL_version sdl_version;
    SDL_GetVersion(&sdl_version);
    sdl_ver = &sdl_version;
    libinfo.append(QString(tr("<a href=\"http://www.libsdl.org/\">SDL2</a>: %1.%2.%3"))
        .arg(sdl_ver->major)
        .arg(sdl_ver->minor)
        .arg(sdl_ver->patch));
    libinfo.append(QString("<br>"));

    const SDL_version *sdlmixer_ver = Mix_Linked_Version();
    libinfo.append(QString(tr("<a href=\"http://www.libsdl.org/\">SDL2_mixer</a>: %1.%2.%3"))
        .arg(sdlmixer_ver->major)
        .arg(sdlmixer_ver->minor)
        .arg(sdlmixer_ver->patch));
    libinfo.append(QString("<br>"));

    // the remaining sdl modules used only in engine, so instead of needlessly linking them here
    // we dynamically call the function returning the linked version
    void *sdlnet_handle = SDL_LoadObject(sopath("SDL_net"));
    if (sdlnet_handle != NULL) {
        SDL_version *(*sdlnet_ver_get)(void) = NULL;
        sdlnet_ver_get = (SDL_version *(*)(void)) SDL_LoadFunction(sdlnet_handle, "SDLNet_Linked_Version");
        if (sdlnet_ver_get != NULL) {
            SDL_version *sdlnet_ver = sdlnet_ver_get();
            libinfo.append(QString(tr("<a href=\"http://www.libsdl.org/\">SDL_net</a>: %1.%2.%3"))
                .arg(sdlnet_ver->major)
                .arg(sdlnet_ver->minor)
                .arg(sdlnet_ver->patch));
            libinfo.append(QString("<br>"));
        }
        SDL_UnloadObject(sdlnet_handle);
    }

    void *sdlimage_handle = SDL_LoadObject(sopath("SDL_image"));
    if (sdlimage_handle != NULL) {
        SDL_version *(*sdlimage_ver_get)(void) = NULL;
        sdlimage_ver_get = (SDL_version *(*)(void)) SDL_LoadFunction(sdlimage_handle, "IMG_Linked_Version");
        if (sdlimage_ver_get != NULL) {
            SDL_version *sdlimage_ver = sdlimage_ver_get();
            libinfo.append(QString(tr("<a href=\"http://www.libsdl.org/\">SDL_image</a>: %1.%2.%3"))
                .arg(sdlimage_ver->major)
                .arg(sdlimage_ver->minor)
                .arg(sdlimage_ver->patch));
            libinfo.append(QString("<br>"));
        }
        SDL_UnloadObject(sdlnet_handle);
    }

    void *sdlttf_handle = SDL_LoadObject(sopath("SDL_ttf"));
    if (sdlttf_handle != NULL) {
        SDL_version *(*sdlttf_ver_get)(void) = NULL;
        sdlttf_ver_get = (SDL_version *(*)(void)) SDL_LoadFunction(sdlttf_handle, "TTF_Linked_Version");
        if (sdlttf_ver_get != NULL) {
            SDL_version *sdlttf_ver = sdlttf_ver_get();
            libinfo.append(QString(tr("<a href=\"http://www.libsdl.org/\">SDL_ttf</a>: %1.%2.%3"))
                .arg(sdlttf_ver->major)
                .arg(sdlttf_ver->minor)
                .arg(sdlttf_ver->patch));
            libinfo.append(QString("<br>"));
        }
        SDL_UnloadObject(sdlnet_handle);
    }


    libinfo.append(QString(tr("<a href=\"http://qt-project.org/\">Qt</a>: %1")).arg(QT_VERSION_STR));
    libinfo.append(QString("<br>"));

#ifdef VIDEOREC
    libinfo.append(QString(tr("<a href=\"http://libav.org\">libavcodec</a>: %1.%2.%3"))
        .arg(LIBAVCODEC_VERSION_MAJOR)
        .arg(LIBAVCODEC_VERSION_MINOR)
        .arg(LIBAVCODEC_VERSION_MICRO));
    libinfo.append(QString("<br>"));
    libinfo.append(QString(tr("<a href=\"http://libav.org\">libavformat</a>: %1.%2.%3"))
        .arg(LIBAVFORMAT_VERSION_MAJOR)
        .arg(LIBAVFORMAT_VERSION_MINOR)
        .arg(LIBAVFORMAT_VERSION_MICRO));
    libinfo.append(QString("<br>"));
    libinfo.append(QString(tr("<a href=\"http://libav.org\">libavutil</a>: %1.%2.%3"))
        .arg(LIBAVUTIL_VERSION_MAJOR)
        .arg(LIBAVUTIL_VERSION_MINOR)
        .arg(LIBAVUTIL_VERSION_MICRO));
    libinfo.append(QString("<br>"));
#endif

    libinfo.append(QString(tr("<a href=\"http://icculus.org/physfs/\">PhysFS</a>: %1.%2.%3"))
        .arg(PHYSFS_VER_MAJOR)
        .arg(PHYSFS_VER_MINOR)
        .arg(PHYSFS_VER_PATCH));
    libinfo.append(QString("<br>"));

    // TODO: how to add Lua information?

    QLabel * lblLibInfo = new QLabel();
    lblLibInfo->setOpenExternalLinks(true);
    lblLibInfo->setText(libinfo);
    lblLibInfo->setWordWrap(true);
    lblLibInfo->setMaximumWidth(280);
    leftLayout->addWidget(lblLibInfo, 0, Qt::AlignHCenter);
    leftLayout->addStretch(1);

    setAcceptDrops(true);
}

void About::dragEnterEvent(QDragEnterEvent * event)
{
    if (event->mimeData()->hasUrls())
    {
        QList<QUrl> urls = event->mimeData()->urls();
        QString url = urls[0].toString();
        if (urls.count() == 1)
            if (url.contains(QRegExp("^file://.*\\.ogg$")))
                event->acceptProposedAction();
    }
}

void About::dropEvent(QDropEvent * event)
{
    QString file =
        event->mimeData()->urls()[0].toString().remove(QRegExp("^file://"));

    SDLInteraction::instance().setMusicTrack(file);

    event->acceptProposedAction();
}
