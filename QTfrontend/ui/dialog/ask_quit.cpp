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

#include <QVBoxLayout>
#include <QLabel>
#include <QDialogButtonBox>
#include <QPushButton>
#include <QTimer>

#include "hwform.h"
#include "ask_quit.h"
#include "pagevideos.h"

HWAskQuitDialog::HWAskQuitDialog(QWidget* parent, HWForm * form) : QDialog(parent)
{
    this->form = form;

    setWindowTitle(tr("Do you really want to quit?"));

    QVBoxLayout * layout = new QVBoxLayout(this);

    QLabel * lbLabel = new QLabel(this);
    lbLabel->setText(QLabel::tr("There are videos that are currently being processed.\n"
                                "Exiting now will abort them.\n"
                                "Do you really want to quit?"));
    layout->addWidget(lbLabel);

    lbList = new QLabel(this);
    layout->addWidget(lbList);
    updateList();

    QDialogButtonBox* dbbButtons = new QDialogButtonBox(this);
    QPushButton * pbYes = dbbButtons->addButton(QDialogButtonBox::Yes);
    QPushButton * pbNo  = dbbButtons->addButton(QDialogButtonBox::No);
    QPushButton * pbMore = dbbButtons->addButton(QPushButton::tr("More info"), QDialogButtonBox::HelpRole);
    layout->addWidget(dbbButtons);

    connect(pbYes,  SIGNAL(clicked()), this, SLOT(accept()));
    connect(pbNo,   SIGNAL(clicked()), this, SLOT(reject()));
    connect(pbMore, SIGNAL(clicked()), this, SLOT(goToPageVideos()));

    // update list periodically
    QTimer * timer = new QTimer(this);
    connect(timer, SIGNAL(timeout()), this, SLOT(updateList()));
    timer->start(200);

    this->setWindowModality(Qt::WindowModal);
}

void HWAskQuitDialog::goToPageVideos()
{
    reject();
    form->GoToVideos();
}

void HWAskQuitDialog::updateList()
{
    QString text = form->ui.pageVideos->getVideosInProgress();
    if (text.isEmpty())
    {
        // automatically exit when everything is finished
        accept();
        return;
    }
    lbList->setText(text);
}
