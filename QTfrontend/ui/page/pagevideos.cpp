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
#include <QPushButton>
#include <QGroupBox>
#include <QComboBox>
#include <QCheckBox>
#include <QLabel>
#include <QLineEdit>
#include <QSpinBox>
#include <QTableWidget>

#include "pagevideos.h"
#include "igbox.h"
#include "libav_iteraction.h"
#include "gameuiconfig.h"

QLayout * PageVideos::bodyLayoutDefinition()
{
    QGridLayout * pageLayout = new QGridLayout();
    pageLayout->setColumnStretch(0, 1);
    pageLayout->setColumnStretch(1, 1);

    {
        IconedGroupBox* groupRec = new IconedGroupBox(this);
        groupRec->setIcon(QIcon(":/res/graphicsicon.png"));
        groupRec->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
        groupRec->setTitle(QGroupBox::tr("Video recording options"));
        QGridLayout * RecLayout = new QGridLayout(groupRec);

        // Label for format
        QLabel *labelFormat = new QLabel(groupRec);
        labelFormat->setText(QLabel::tr("Format"));
        RecLayout->addWidget(labelFormat, 0, 0);

        // List of supported formats
        CBAVFormats = new QComboBox(groupRec);
        RecLayout->addWidget(CBAVFormats, 0, 1, 1, 4);
        LibavIteraction::instance().FillFormats(CBAVFormats);

        QFrame * hr = new QFrame(groupRec);
        hr->setFrameStyle(QFrame::HLine);
        hr->setLineWidth(3);
        hr->setFixedHeight(10);
        RecLayout->addWidget(hr, 1, 0, 1, 5);

        // Label for audio codec
        QLabel *labelACodec = new QLabel(groupRec);
        labelACodec->setText(QLabel::tr("Audio codec"));
        RecLayout->addWidget(labelACodec, 2, 0);

        // List of supported audio codecs
        CBAudioCodecs = new QComboBox(groupRec);
        RecLayout->addWidget(CBAudioCodecs, 2, 1, 1, 3);

        // record audio
        CBRecordAudio = new QCheckBox(groupRec);
        CBRecordAudio->setText(QCheckBox::tr("Record audio"));
        RecLayout->addWidget(CBRecordAudio, 2, 4);

        hr = new QFrame(groupRec);
        hr->setFrameStyle(QFrame::HLine);
        hr->setLineWidth(3);
        hr->setFixedHeight(10);
        RecLayout->addWidget(hr, 3, 0, 1, 5);

        // Label for video codec
        QLabel *labelVCodec = new QLabel(groupRec);
        labelVCodec->setText(QLabel::tr("Video codec"));
        RecLayout->addWidget(labelVCodec, 4, 0);

        // List of supported video codecs
        CBVideoCodecs = new QComboBox(groupRec);
        RecLayout->addWidget(CBVideoCodecs, 4, 1, 1, 4);

        // Label for resolution
        QLabel *labelRes = new QLabel(groupRec);
        labelRes->setText(QLabel::tr("Resolution"));
        RecLayout->addWidget(labelRes, 5, 0);

        // width
        widthEdit = new QLineEdit(groupRec);
        widthEdit->setValidator(new QIntValidator(this));
        RecLayout->addWidget(widthEdit, 5, 1);

        // x
        QLabel *labelX = new QLabel(groupRec);
        labelX->setText("X");
        RecLayout->addWidget(labelX, 5, 2);

        // height
        heightEdit = new QLineEdit(groupRec);
        heightEdit->setValidator(new QIntValidator(groupRec));
        RecLayout->addWidget(heightEdit, 5, 3);

        // use game res
        CBUseGameRes = new QCheckBox(groupRec);
        CBUseGameRes->setText(QCheckBox::tr("Use game resolution"));
        RecLayout->addWidget(CBUseGameRes, 5, 4);

        // Label for framerate
        QLabel *labelFramerate = new QLabel(groupRec);
        labelFramerate->setText(QLabel::tr("Framerate"));
        RecLayout->addWidget(labelFramerate, 6, 0);

        // framerate
        framerateBox = new QSpinBox(groupRec);
        framerateBox->setRange(1, 200);
        framerateBox->setSingleStep(1);
        RecLayout->addWidget(framerateBox, 6, 1);

        BtnDefaults = new QPushButton(groupRec);
        BtnDefaults->setText(QPushButton::tr("Set default options"));
        RecLayout->addWidget(BtnDefaults, 7, 0, 1, 5);

        pageLayout->addWidget(groupRec, 0, 0);
    }

    {
        IconedGroupBox* groupTable = new IconedGroupBox(this);
        //groupRec->setContentTopPadding(0);
        groupTable->setIcon(QIcon(":/res/graphicsicon.png"));
        groupTable->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
        groupTable->setTitle(QGroupBox::tr("Videos"));

        QStringList columns;
        columns << tr("Name") << tr("Lenght") << tr("...");

        filesTable = new QTableWidget(groupTable);
        filesTable->setColumnCount(3);
        filesTable->setHorizontalHeaderLabels(columns);
        QVBoxLayout *box = new QVBoxLayout(groupTable);
        box->addWidget(filesTable);

        pageLayout->addWidget(groupTable, 0, 1, 2, 1);
    }

    return pageLayout;
}

QLayout * PageVideos::footerLayoutDefinition()
{
    return NULL;
}

void PageVideos::connectSignals()
{
    connect(CBUseGameRes, SIGNAL(stateChanged(int)), this, SLOT(changeUseGameRes(int)));
    connect(CBRecordAudio, SIGNAL(stateChanged(int)), this, SLOT(changeRecordAudio(int)));
    connect(CBAVFormats, SIGNAL(currentIndexChanged(int)), this, SLOT(changeAVFormat(int)));
    connect(BtnDefaults, SIGNAL(clicked()), this, SLOT(setDefaultOptions()));
}

PageVideos::PageVideos(QWidget* parent) : AbstractPage(parent)
{
    initPage();
}

void PageVideos::changeAVFormat(int index)
{
    QString prevVCodec = getVideoCodec();
    QString prevACodec = getAudioCodec();
    CBVideoCodecs->clear();
    CBAudioCodecs->clear();
    LibavIteraction::instance().FillCodecs(CBAVFormats->itemData(index), CBVideoCodecs, CBAudioCodecs);
    if (CBAudioCodecs->count() == 0)
    {
        CBRecordAudio->setChecked(false);
        CBRecordAudio->setEnabled(false);
    }
    else
        CBRecordAudio->setEnabled(true);
    int iVCodec = CBVideoCodecs->findData(prevVCodec);
    if (iVCodec != -1)
        CBVideoCodecs->setCurrentIndex(iVCodec);
    int iACodec = CBAudioCodecs->findData(prevACodec);
    if (iACodec != -1)
        CBAudioCodecs->setCurrentIndex(iACodec);
}

void PageVideos::changeUseGameRes(int state)
{
    if (state && config)
    {
        QRect resolution = config->vid_Resolution();
        widthEdit->setText(QString::number(resolution.width()));
        heightEdit->setText(QString::number(resolution.height()));
    }
    widthEdit->setEnabled(!state);
    heightEdit->setEnabled(!state);
}

void PageVideos::changeRecordAudio(int state)
{
    CBAudioCodecs->setEnabled(!!state);
}

void PageVideos::setDefaultCodecs()
{
    if (tryCodecs("mp4", "libx264", "libmp3lame"))
        return;
    if (tryCodecs("mp4", "libx264", "ac3_fixed"))
        return;
    if (tryCodecs("avi", "libxvid", "libmp3lame"))
        return;
    if (tryCodecs("avi", "libxvid", "ac3_fixed"))
        return;
    if (tryCodecs("avi", "mpeg4", "libmp3lame"))
        return;
    if (tryCodecs("avi", "mpeg4", "ac3_fixed"))
        return;

    // this shouldn't happen, just in case
    if (tryCodecs("ogg", "libtheora", "libvorbis"))
        return;
    tryCodecs("ogg", "libtheora", "flac");
}

void PageVideos::setDefaultOptions()
{
    framerateBox->setValue(25);
    CBRecordAudio->setChecked(true);
    CBUseGameRes->setChecked(true);
    setDefaultCodecs();
}

bool PageVideos::tryCodecs(const QString & format, const QString & vcodec, const QString & acodec)
{
    int iFormat = CBAVFormats->findData(format);
    if (iFormat == -1)
        return false;
    CBAVFormats->setCurrentIndex(iFormat);

    int iVCodec = CBVideoCodecs->findData(vcodec);
    if (iVCodec == -1)
        return false;
    CBVideoCodecs->setCurrentIndex(iVCodec);

    int iACodec = CBAudioCodecs->findData(acodec);
    if (iACodec == -1 && CBRecordAudio->isChecked())
        return false;
    if (iACodec != -1)
        CBAudioCodecs->setCurrentIndex(iACodec);

    return true;
}
