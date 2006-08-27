/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * Distributed under the terms of the BSD-modified licence:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * with the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <QVBoxLayout>
#include <QGridLayout>
#include "ui_hwform.h"
#include "pages.h"

void Ui_HWForm::setupUi(QMainWindow *HWForm)
{
	SetupFonts();

	HWForm->setObjectName(QString::fromUtf8("HWForm"));
	HWForm->resize(QSize(620, 430).expandedTo(HWForm->minimumSizeHint()));
	HWForm->setMinimumSize(QSize(620, 430));
	HWForm->setWindowTitle(QMainWindow::tr("-= by unC0Rr =-"));
	centralWidget = new QWidget(HWForm);
	centralWidget->setObjectName(QString::fromUtf8("centralWidget"));

	centralWidget = new QWidget(HWForm);
	centralWidget->setObjectName(QString::fromUtf8("centralWidget"));

	SetupPages(centralWidget);

	HWForm->setCentralWidget(centralWidget);

	Pages->setCurrentIndex(0);

	QMetaObject::connectSlotsByName(HWForm);
}

void Ui_HWForm::SetupFonts()
{
	font14 = new QFont("MS Shell Dlg", 14);
}

void Ui_HWForm::SetupPages(QWidget *Parent)
{
	Pages =	new QStackedLayout(Parent);

	pageLocalGame = new PageLocalGame();
	Pages->addWidget(pageLocalGame);

	pageEditTeam = new PageEditTeam();
	Pages->addWidget(pageEditTeam);

	pageOptions = new PageOptions();
	Pages->addWidget(pageOptions);

	pageMultiplayer = new PageMultiplayer();
	Pages->addWidget(pageMultiplayer);

	pagePlayDemo =	new PagePlayDemo();
	Pages->addWidget(pagePlayDemo);

	pageNet = new PageNet();
	Pages->addWidget(pageNet);

	pageNetChat	= new PageNetChat();
	Pages->addWidget(pageNetChat);

	pageNetGame	= new PageNetGame();
	Pages->addWidget(pageNetGame);

	pageMain = new PageMain();
	Pages->addWidget(pageMain);
}
