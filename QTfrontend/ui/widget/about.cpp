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
#include <QMimeData>
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

QString About::getCreditsHtml()
{
    // Open the credits file

    /* *** FILE FORMAT OF CREDITS FILE ***
    The credits file is an RFC-4180-compliant CSV file with 3 columns:
    * Task/contribution
    * Contributor name
    * Contributor e-mail

    The first and last columns are optional.

    There are special rows, which are marked by putting a "!__" in the
    beginning of the first. The following special rows are supported:

    !__SECTION: Section. Column 1 is the section name
    !__SUBSECTION: Subsection. Column 1 is the subsection name
    !__MISC: Placeholder for other or unknown authors
    */
    QFile creditsFile(":/res/credits.csv");
    if (!creditsFile.open(QIODevice::ReadOnly))
    {
        qWarning("ERROR: Credits file could not be opened!");
        return "<p>ERROR: Credits file could not be opened!</p>";
    }
    QString creditsString = creditsFile.readAll();
    QString out = QString("<h1>" + tr("Credits") + "</h1>\n");
    QStringList cells = QStringList() << QString("") << QString("") << QString("");
    bool firstSection = true;
    unsigned long int column = 0;
    unsigned long int charInCell = 0;
    bool isInQuote = false;
    bool ignoreChar = false;
    bool lineComplete = false;
    QChar currChar;
    QChar prevChar;
    for(long long int i = 0; i<creditsString.length(); i++)
    {
        currChar = creditsString.at(i);
        QString task, name, mail;
        if(currChar == '"')
        {
            if(charInCell == 0)
            {
                isInQuote = true;
                ignoreChar = true;
            }
            else if(isInQuote && prevChar != '"')
            {
                ignoreChar = true;
            }
        }
        else if(isInQuote && charInCell > 0 && prevChar == '"' && (currChar == '\r' || currChar == ','))
        {
            isInQuote = false;
            ignoreChar = true;
        }

        charInCell++;
        if(!isInQuote && currChar == ',')
        {
            column++;
            charInCell = 0;
        }
        else if(!isInQuote && currChar == '\n' && prevChar == '\r')
        {
            lineComplete = true;
        }
        if(!isInQuote && (currChar == '\r' || currChar == '\n' || currChar == ','))
        {
            ignoreChar = true;
        }


        if(!ignoreChar)
        {
            cells[column].append(currChar);
        }
        ignoreChar = false;

        if(lineComplete)
        {
            task = cells[0];
            name = cells[1];
            mail = cells[2];

            if(task == "!__SECTION")
            {
                if (!firstSection)
                    out = out + "</ul>\n";
                out = out + "<h2>" + name + "</h2>\n<ul>\n";
                firstSection = false;
            }
            else if(task == "!__SUBSECTION")
            {
                out = out + "</ul>\n";
                out = out + "<h3>" + name + "</h3>\n<ul>\n";
            }
            else if(task == "!__MISC")
            {
                out = out + "<li>" + tr("Other people") + "</li>" + "\n";
            }
            else
            {
                QString mailLink = QString("<a href=\"mailto:%1\">%1</a>").arg(mail);
                if(task.isEmpty() && mail.isEmpty())
                {
                    out = out + "<li>" + name + "</li>\n";
                }
                else if(task.isEmpty())
                {
                    out = out + "<li>" + tr("%1 &lt;%2&gt;").arg(name).arg(mailLink) + "</li>\n";
                }
                else if(mail.isEmpty())
                {
                    out = out + "<li>" + tr("%1: %2").arg(task).arg(name) + "</li>\n";
                }
                else
                {
                    out = out + "<li>" + tr("%1: %2 &lt;%3&gt;").arg(task).arg(name).arg(mailLink) + "</li>\n";
                }
            }
            lineComplete = false;
            column = 0;
            cells[0] = "";
            cells[1] = "";
            cells[2] = "";
            charInCell = 0;
        }

        prevChar = currChar;
    }
    creditsFile.close();
    out = out + "</ul>";
    return out;
}

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
        //: %1 contains Hedgewars' version number
        "<div align=\"center\"><h1>"+QString(tr("Hedgewars %1")).arg(*cVersionString) + "</h1>"
        //: “Revision” stands for a revision in Mercurial, a distributed version control system. %1 is the revision, %2 is the hexadecimal hash.
        "<h3>" + QString(tr("Revision %1 (%2)")).arg(*cRevisionString, *cHashString) + "</h3>"
        //: %1 is replaced by the URL of Hedgewars.
        "<p>" + QString(tr("Visit our homepage: %1"))
        .arg("<a href=\"https://www.hedgewars.org/\">https://www.hedgewars.org/</a>") + "</p>" +
        //: %1 is the name of a license
        tr("This program is distributed under the %1.")
	.arg("<a href=\"https://www.gnu.org/licenses/gpl-2.0.html\">"+
        //: Short for “GNU General Public License version 2”
        tr("GNU GPL v2")+"</a>") +
        "</div>"
    );
    lbl1->setWordWrap(true);
    mainLayout->addWidget(lbl1, 0, 1);

    /* Credits */
    creditsBrowser = new QTextBrowser(this);
    creditsBrowser->setOpenExternalLinks(true);
    QString credits = getCreditsHtml();

    QString header =
        "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">"
        "<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\" xml:lang=\"en\">"
        "<head>"
        "<title>Hedgewars Credits</title>"
        "<meta http-equiv=\"content-type\" content=\"text/html;charset=utf-8\" />"
        "<style type=\"text/css\">"
        "     body { color: orange; }"
        "     a { color: #ffe270; }"
        "     a:hover { color: yellow; }"
        "     ul { list-style-type: none; }"
        "</style>"
        "</head>"
        "<body>"
        "";
    QString footer =
        ""
        "</body></html>";

    creditsBrowser->setHtml(header + credits + footer);
    mainLayout->addWidget(creditsBrowser, 1, 1);

    /* Library information */

    //: For the version numbers of Hedgewars' software dependencies
    QString libinfo = QString(tr("Dependency versions:") + QString("<br>"));

#if defined(__GNUC__)
    libinfo.append(QString(tr("<a href=\"https://gcc.gnu.org\">GCC</a>: %1")).arg(__VERSION__));
#elif defined(WIN32_VCPKG)
    libinfo.append(QString(tr("<a href=\"https://visualstudio.microsoft.com\">VC++</a>: %1")).arg(_MSC_FULL_VER));
#elif defined(__VERSION__)
    libinfo.append(QString(tr("Unknown Compiler: %1")).arg(__VERSION__));
#else
    libinfo.append(QString(tr("Unknown Compiler")));
#endif
    libinfo.append(QString("<br>"));

    const SDL_version *sdl_ver;
    SDL_version sdl_version;
    SDL_GetVersion(&sdl_version);
    sdl_ver = &sdl_version;
    libinfo.append(QString(tr("<a href=\"https://www.libsdl.org/\">SDL2</a>: %1.%2.%3"))
        .arg(sdl_ver->major)
        .arg(sdl_ver->minor)
        .arg(sdl_ver->patch));
    libinfo.append(QString("<br>"));

    const SDL_version *sdlmixer_ver = Mix_Linked_Version();
    libinfo.append(QString(tr("<a href=\"https://www.libsdl.org/\">SDL2_mixer</a>: %1.%2.%3"))
        .arg(sdlmixer_ver->major)
        .arg(sdlmixer_ver->minor)
        .arg(sdlmixer_ver->patch));
    libinfo.append(QString("<br>"));

    // the remaining sdl modules used only in engine, so instead of needlessly linking them here
    // we dynamically call the function returning the linked version
    void *sdlnet_handle = SDL_LoadObject(sopath("SDL2_net"));
    if (sdlnet_handle != NULL) {
        SDL_version *(*sdlnet_ver_get)(void) = NULL;
        sdlnet_ver_get = (SDL_version *(*)(void)) SDL_LoadFunction(sdlnet_handle, "SDLNet_Linked_Version");
        if (sdlnet_ver_get != NULL) {
            SDL_version *sdlnet_ver = sdlnet_ver_get();
            libinfo.append(QString(tr("<a href=\"https://www.libsdl.org/\">SDL2_net</a>: %1.%2.%3"))
                .arg(sdlnet_ver->major)
                .arg(sdlnet_ver->minor)
                .arg(sdlnet_ver->patch));
            libinfo.append(QString("<br>"));
        }
        SDL_UnloadObject(sdlnet_handle);
    }

    void *sdlimage_handle = SDL_LoadObject(sopath("SDL2_image"));
    if (sdlimage_handle != NULL) {
        SDL_version *(*sdlimage_ver_get)(void) = NULL;
        sdlimage_ver_get = (SDL_version *(*)(void)) SDL_LoadFunction(sdlimage_handle, "IMG_Linked_Version");
        if (sdlimage_ver_get != NULL) {
            SDL_version *sdlimage_ver = sdlimage_ver_get();
            libinfo.append(QString(tr("<a href=\"https://www.libsdl.org/\">SDL2_image</a>: %1.%2.%3"))
                .arg(sdlimage_ver->major)
                .arg(sdlimage_ver->minor)
                .arg(sdlimage_ver->patch));
            libinfo.append(QString("<br>"));
        }
        SDL_UnloadObject(sdlimage_handle);
    }

    void *sdlttf_handle = SDL_LoadObject(sopath("SDL2_ttf"));
    if (sdlttf_handle != NULL) {
        SDL_version *(*sdlttf_ver_get)(void) = NULL;
        sdlttf_ver_get = (SDL_version *(*)(void)) SDL_LoadFunction(sdlttf_handle, "TTF_Linked_Version");
        if (sdlttf_ver_get != NULL) {
            SDL_version *sdlttf_ver = sdlttf_ver_get();
            libinfo.append(QString(tr("<a href=\"https://www.libsdl.org/\">SDL2_ttf</a>: %1.%2.%3"))
                .arg(sdlttf_ver->major)
                .arg(sdlttf_ver->minor)
                .arg(sdlttf_ver->patch));
            libinfo.append(QString("<br>"));
        }
        SDL_UnloadObject(sdlttf_handle);
    }


    libinfo.append(QString(tr("<a href=\"https://www.qt.io/developers/\">Qt</a>: %1")).arg(QT_VERSION_STR));
    libinfo.append(QString("<br>"));

#ifdef VIDEOREC
    libinfo.append(QString(tr("<a href=\"https://libav.org\">libavcodec</a>: %1.%2.%3"))
        .arg(LIBAVCODEC_VERSION_MAJOR)
        .arg(LIBAVCODEC_VERSION_MINOR)
        .arg(LIBAVCODEC_VERSION_MICRO));
    libinfo.append(QString("<br>"));
    libinfo.append(QString(tr("<a href=\"https://libav.org\">libavformat</a>: %1.%2.%3"))
        .arg(LIBAVFORMAT_VERSION_MAJOR)
        .arg(LIBAVFORMAT_VERSION_MINOR)
        .arg(LIBAVFORMAT_VERSION_MICRO));
    libinfo.append(QString("<br>"));
    libinfo.append(QString(tr("<a href=\"https://libav.org\">libavutil</a>: %1.%2.%3"))
        .arg(LIBAVUTIL_VERSION_MAJOR)
        .arg(LIBAVUTIL_VERSION_MINOR)
        .arg(LIBAVUTIL_VERSION_MICRO));
    libinfo.append(QString("<br>"));
#endif

    libinfo.append(QString(tr("<a href=\"https://icculus.org/physfs/\">PhysFS</a>: %1.%2.%3"))
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
