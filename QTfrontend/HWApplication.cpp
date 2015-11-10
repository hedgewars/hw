/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2012 Vittorio Giovara <vittorio.giovara@gmail.com>
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

#include "HWApplication.h"
#include <QFileOpenEvent>
#include <QEvent>

#include "MessageDialog.h"

#if !defined(Q_OS_WIN)
#include "signal.h"
#endif

#if !defined(Q_OS_WIN)
void terminateFrontend(int signal)
{
    Q_UNUSED(signal);
    QCoreApplication::exit(0);
}
#endif

HWApplication::HWApplication(int &argc, char **argv) :
    QApplication(argc, argv)
{
    form = 0;

#if !defined(Q_OS_WIN)
    signal(SIGINT, &terminateFrontend);
#endif
#if 0
    qDebug("%s called with", argv[0]);
    for (int i = 1; i < argc; i++)
        qDebug("%d: %s", i, argv[i]);
#endif
    // on Windows, sending an event right away leads to a segfault
    // so we use urlString to save the data and send the event just before the app.exec()
    urlString = NULL;
    if (argc > 1) {
        urlString = new QString(argv[1]);
        if (urlString->contains("//", Qt::CaseInsensitive) == false) {
            delete urlString;
            urlString = NULL;
        }
    }
}

void HWApplication::fakeEvent()
{
    QUrl parsedUrl(*urlString);
    delete urlString;
    urlString = NULL;
    QFileOpenEvent *openEvent = new QFileOpenEvent(parsedUrl);
    QCoreApplication::sendEvent(QCoreApplication::instance(), openEvent);
}

bool HWApplication::event(QEvent *event)
{
    QFileOpenEvent *openEvent;
    QString scheme, path, address;

    if (event->type() == QEvent::FileOpen) {
        openEvent = (QFileOpenEvent *)event;
        scheme = openEvent->url().scheme();
        path = openEvent->url().path();
        address = openEvent->url().host();

        QFile file(path);
        if (scheme == "file" && file.exists()) {
            form->PlayDemoQuick(path);
            return true;
        } else if (scheme == "hwplay") {
            int port = openEvent->url().port(NETGAME_DEFAULT_PORT);
            if (address == "")
                address = NETGAME_DEFAULT_SERVER;
            form->NetConnectQuick(address, (quint16) port);
            return true;
        } else {
            const QString errmsg = tr("Scheme '%1' not supported").arg(scheme);
            MessageDialog::ShowErrorMessage(errmsg, form);
            return false;
        }
    }

    return QApplication::event(event);
}


