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

#include <QHBoxLayout>
#include <QLineEdit>
#include <QTextBrowser>
#include <QLabel>

#include "pagefeedback.h"
#include "hwconsts.h"

QLayout * PageFeedback::bodyLayoutDefinition()
{
    QVBoxLayout * pageLayout = new QVBoxLayout();
    QHBoxLayout * summaryLayout = new QHBoxLayout();

    info = new QLabel();
    info->setText(
        "<style type=\"text/css\">"
        "a { color: #ffcc00; }"
        "</style>"
        "<div align=\"center\"><h1>Please give us a feedback!</h1>"
        "<h3>We are always happy about suggestions, ideas or bug reports.<h3>"
        "<h4>The feedback will be posted as a new issue on our Google Code page.<h4>"
        "</div>"
    );
    pageLayout->addWidget(info);

    label_summary = new QLabel();
    label_summary->setText(QLabel::tr("Summary   "));
    summaryLayout->addWidget(label_summary);
    summary = new QLineEdit();
    summaryLayout->addWidget(summary);
    pageLayout->addLayout(summaryLayout);

    label_description = new QLabel();
    label_description->setText(QLabel::tr("Description"));
    pageLayout->addWidget(label_description, 0, Qt::AlignHCenter);
    description = new QTextBrowser();
    description->setReadOnly(false);
    pageLayout->addWidget(description);

    return pageLayout;
}

QLayout * PageFeedback::footerLayoutDefinition()
{
    QHBoxLayout * bottomLayout = new QHBoxLayout();

    bottomLayout->setStretch(0,1);
    //TODO: create logo for send button
    BtnSend = addButton("Send", bottomLayout, 0, false);
    bottomLayout->insertStretch(0);

    return bottomLayout;
}

void PageFeedback::connectSignals()
{
    //TODO
}

PageFeedback::PageFeedback(QWidget* parent) : AbstractPage(parent)
{
    initPage();

}
