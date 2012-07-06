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
#include <QDir>
#include <QProgressBar>
#include <QStringList>
#include <QDesktopServices>
#include <QUrl>
#include <QList>
#include <QMessageBox>
#include <QHeaderView>
#include <QKeyEvent>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QFileSystemWatcher>

#include "hwconsts.h"
#include "pagevideos.h"
#include "igbox.h"
#include "libav_iteraction.h"
#include "gameuiconfig.h"
#include "recorder.h"
#include "ask_quit.h"

const int ThumbnailSize = 400;

// columns in table with list of video files
enum VideosColumns
{
    vcName,
    vcSize,
    vcProgress,

    vcNumColumns,
};

class VideoItem : public QTableWidgetItem
{
    // note: QTableWidgetItem is not Q_OBJECT

    public:
        VideoItem(const QString& name);
        ~VideoItem();

        QString name;
        QString desc; // description
        HWRecorder * pRecorder; // non NULL if file is being encoded
        bool seen; // used when updating directory
        float lastSizeUpdate;
        float progress;

        bool ready()
        { return !pRecorder; }

        QString path()
        { return cfgdir->absoluteFilePath("Videos/" + name);  }
};

VideoItem::VideoItem(const QString& name)
    : QTableWidgetItem(name, UserType)
{
    this->name = name;
    pRecorder = NULL;
    lastSizeUpdate = 0;
    progress = 0;
}

VideoItem::~VideoItem()
{}

QLayout * PageVideos::bodyLayoutDefinition()
{
    QGridLayout * pPageLayout = new QGridLayout();
    pPageLayout->setColumnStretch(0, 1);
    pPageLayout->setColumnStretch(1, 2);
    pPageLayout->setRowStretch(0, 1);
    pPageLayout->setRowStretch(1, 1);

    {
        IconedGroupBox* pOptionsGroup = new IconedGroupBox(this);
        pOptionsGroup->setIcon(QIcon(":/res/graphicsicon.png"));
        pOptionsGroup->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
        pOptionsGroup->setTitle(QGroupBox::tr("Video recording options"));
        QGridLayout * pOptLayout = new QGridLayout(pOptionsGroup);

        // label for format
        QLabel *labelFormat = new QLabel(pOptionsGroup);
        labelFormat->setText(QLabel::tr("Format"));
        pOptLayout->addWidget(labelFormat, 0, 0);

        // list of supported formats
        comboAVFormats = new QComboBox(pOptionsGroup);
        pOptLayout->addWidget(comboAVFormats, 0, 1, 1, 4);
        LibavIteraction::instance().fillFormats(comboAVFormats);

        // separator
        QFrame * hr = new QFrame(pOptionsGroup);
        hr->setFrameStyle(QFrame::HLine);
        hr->setLineWidth(3);
        hr->setFixedHeight(10);
        pOptLayout->addWidget(hr, 1, 0, 1, 5);

        // label for audio codec
        QLabel *labelACodec = new QLabel(pOptionsGroup);
        labelACodec->setText(QLabel::tr("Audio codec"));
        pOptLayout->addWidget(labelACodec, 2, 0);

        // list of supported audio codecs
        comboAudioCodecs = new QComboBox(pOptionsGroup);
        pOptLayout->addWidget(comboAudioCodecs, 2, 1, 1, 3);

        // checkbox 'record audio'
        checkRecordAudio = new QCheckBox(pOptionsGroup);
        checkRecordAudio->setText(QCheckBox::tr("Record audio"));
        pOptLayout->addWidget(checkRecordAudio, 2, 4);

        // separator
        hr = new QFrame(pOptionsGroup);
        hr->setFrameStyle(QFrame::HLine);
        hr->setLineWidth(3);
        hr->setFixedHeight(10);
        pOptLayout->addWidget(hr, 3, 0, 1, 5);

        // label for video codec
        QLabel *labelVCodec = new QLabel(pOptionsGroup);
        labelVCodec->setText(QLabel::tr("Video codec"));
        pOptLayout->addWidget(labelVCodec, 4, 0);

        // list of supported video codecs
        comboVideoCodecs = new QComboBox(pOptionsGroup);
        pOptLayout->addWidget(comboVideoCodecs, 4, 1, 1, 4);

        // label for resolution
        QLabel *labelRes = new QLabel(pOptionsGroup);
        labelRes->setText(QLabel::tr("Resolution"));
        pOptLayout->addWidget(labelRes, 5, 0);

        // width
        widthEdit = new QLineEdit(pOptionsGroup);
        widthEdit->setValidator(new QIntValidator(this));
        pOptLayout->addWidget(widthEdit, 5, 1);

        // x
        QLabel *labelX = new QLabel(pOptionsGroup);
        labelX->setText("X");
        pOptLayout->addWidget(labelX, 5, 2);

        // height
        heightEdit = new QLineEdit(pOptionsGroup);
        heightEdit->setValidator(new QIntValidator(pOptionsGroup));
        pOptLayout->addWidget(heightEdit, 5, 3);

        // checkbox 'use game resolution'
        checkUseGameRes = new QCheckBox(pOptionsGroup);
        checkUseGameRes->setText(QCheckBox::tr("Use game resolution"));
        pOptLayout->addWidget(checkUseGameRes, 5, 4);

        // label for framerate
        QLabel *labelFramerate = new QLabel(pOptionsGroup);
        labelFramerate->setText(QLabel::tr("Framerate"));
        pOptLayout->addWidget(labelFramerate, 6, 0);

        // framerate
        framerateBox = new QSpinBox(pOptionsGroup);
        framerateBox->setRange(1, 200);
        framerateBox->setSingleStep(1);
        pOptLayout->addWidget(framerateBox, 6, 1);

        // button 'set default options'
        btnDefaults = new QPushButton(pOptionsGroup);
        btnDefaults->setText(QPushButton::tr("Set default options"));
        pOptLayout->addWidget(btnDefaults, 7, 0, 1, 5);

        pPageLayout->addWidget(pOptionsGroup, 1, 0);
    }

    {
        IconedGroupBox* pTableGroup = new IconedGroupBox(this);
        pTableGroup->setIcon(QIcon(":/res/graphicsicon.png"));
        pTableGroup->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
        pTableGroup->setTitle(QGroupBox::tr("Videos"));

        QStringList columns;
        columns << tr("Name");
        columns << tr("Size");
        columns << "";

        filesTable = new QTableWidget(pTableGroup);
        filesTable->setColumnCount(vcNumColumns);
        filesTable->setHorizontalHeaderLabels(columns);
        filesTable->setSelectionBehavior(QAbstractItemView::SelectRows);
        filesTable->setEditTriggers(QAbstractItemView::SelectedClicked);
        filesTable->verticalHeader()->hide();

        QHeaderView * header = filesTable->horizontalHeader();
        header->setResizeMode(vcName, QHeaderView::ResizeToContents);
        header->setResizeMode(vcSize, QHeaderView::Fixed);
        header->resizeSection(vcSize, 100);
        header->setStretchLastSection(true);

        btnOpenDir = new QPushButton(QPushButton::tr("Open videos directory"), pTableGroup);

        QVBoxLayout *box = new QVBoxLayout(pTableGroup);
        box->addWidget(filesTable);
        box->addWidget(btnOpenDir);

        pPageLayout->addWidget(pTableGroup, 0, 1, 2, 1);
    }

    {
        IconedGroupBox* pDescGroup = new IconedGroupBox(this);
        pDescGroup->setIcon(QIcon(":/res/graphicsicon.png"));
        pDescGroup->setTitle(QGroupBox::tr("Description"));

        QVBoxLayout* pDescLayout = new QVBoxLayout(pDescGroup);
        QHBoxLayout* pTopDescLayout = new QHBoxLayout(0);    // picture and text
        QHBoxLayout* pBottomDescLayout = new QHBoxLayout(0); // buttons

        // label with thumbnail picture
        labelThumbnail = new QLabel(pDescGroup);
        labelThumbnail->setAlignment(Qt::AlignHCenter | Qt::AlignVCenter);
        labelThumbnail->setStyleSheet(
                    "QFrame {"
                    "border: solid;"
                    "border-width: 3px;"
                    "border-color: #ffcc00;"
                    "border-radius: 4px;"
                    "}" );
        pTopDescLayout->addWidget(labelThumbnail);

        // label with file description
        labelDesc = new QLabel(pDescGroup);
        labelDesc->setAlignment(Qt::AlignLeft | Qt::AlignTop);
        pTopDescLayout->addWidget(labelDesc);

        // buttons: play and delete
        btnPlay = new QPushButton(QPushButton::tr("Play"), pDescGroup);
        pBottomDescLayout->addWidget(btnPlay);
        btnDelete = new QPushButton(QPushButton::tr("Delete"), pDescGroup);
        pBottomDescLayout->addWidget(btnDelete);

        pDescLayout->addStretch(1);
        pDescLayout->addLayout(pTopDescLayout, 0);
        pDescLayout->addStretch(1);
        pDescLayout->addLayout(pBottomDescLayout, 0);

        pPageLayout->addWidget(pDescGroup, 0, 0);
    }

    return pPageLayout;
}

QLayout * PageVideos::footerLayoutDefinition()
{
    return NULL;
}

void PageVideos::connectSignals()
{
    connect(checkUseGameRes, SIGNAL(stateChanged(int)), this, SLOT(changeUseGameRes(int)));
    connect(checkRecordAudio, SIGNAL(stateChanged(int)), this, SLOT(changeRecordAudio(int)));
    connect(comboAVFormats, SIGNAL(currentIndexChanged(int)), this, SLOT(changeAVFormat(int)));
    connect(btnDefaults, SIGNAL(clicked()), this, SLOT(setDefaultOptions()));
    connect(filesTable, SIGNAL(cellDoubleClicked(int, int)), this, SLOT(cellDoubleClicked(int, int)));
    connect(filesTable, SIGNAL(cellChanged(int,int)), this, SLOT(cellChanged(int, int)));
    connect(filesTable, SIGNAL(currentCellChanged(int,int,int,int)), this, SLOT(currentCellChanged(int,int,int,int)));
    connect(btnPlay,   SIGNAL(clicked()), this, SLOT(playSelectedFile()));
    connect(btnDelete, SIGNAL(clicked()), this, SLOT(deleteSelectedFiles()));
    connect(btnOpenDir, SIGNAL(clicked()), this, SLOT(openVideosDirectory()));

    QString path = cfgdir->absolutePath() + "/Videos";
    QFileSystemWatcher * pWatcher = new QFileSystemWatcher(this);
    pWatcher->addPath(path);
    connect(pWatcher, SIGNAL(directoryChanged(const QString &)), this, SLOT(updateFileList(const QString &)));
    updateFileList(path);
}

PageVideos::PageVideos(QWidget* parent) : AbstractPage(parent),
    config(0)
{
    nameChangedFromCode = false;
    numRecorders = 0;
    initPage();
}

// user changed file format, we need to update list of codecs
void PageVideos::changeAVFormat(int index)
{
    // remember selected codecs
    QString prevVCodec = videoCodec();
    QString prevACodec = audioCodec();

    // clear lists of codecs
    comboVideoCodecs->clear();
    comboAudioCodecs->clear();

    // get list of codecs for specified format
    LibavIteraction::instance().fillCodecs(comboAVFormats->itemData(index).toString(), comboVideoCodecs, comboAudioCodecs);

    // disable audio if there is no audio codec
    if (comboAudioCodecs->count() == 0)
    {
        checkRecordAudio->setChecked(false);
        checkRecordAudio->setEnabled(false);
    }
    else
        checkRecordAudio->setEnabled(true);

    // restore selected codecs if possible
    int iVCodec = comboVideoCodecs->findData(prevVCodec);
    if (iVCodec != -1)
        comboVideoCodecs->setCurrentIndex(iVCodec);
    int iACodec = comboAudioCodecs->findData(prevACodec);
    if (iACodec != -1)
        comboAudioCodecs->setCurrentIndex(iACodec);
}

// user switched checkbox 'use game resolution'
void PageVideos::changeUseGameRes(int state)
{
    if (state && config)
    {
        // set resolution to game resolution
        QRect resolution = config->vid_Resolution();
        widthEdit->setText(QString::number(resolution.width()));
        heightEdit->setText(QString::number(resolution.height()));
    }
    widthEdit->setEnabled(!state);
    heightEdit->setEnabled(!state);
}

// user switched checkbox 'record audio'
void PageVideos::changeRecordAudio(int state)
{
    comboAudioCodecs->setEnabled(!!state);
}

void PageVideos::setDefaultCodecs()
{
    if (tryCodecs("mp4", "libx264", "libmp3lame"))
        return;
    if (tryCodecs("mp4", "libx264", "libfaac"))
        return;
    if (tryCodecs("mp4", "libx264", "libvo_aacenc"))
        return;
    if (tryCodecs("mp4", "libx264", "aac"))
        return;
    if (tryCodecs("mp4", "libx264", "mp2"))
        return;
    if (tryCodecs("avi", "libxvid", "libmp3lame"))
        return;
    if (tryCodecs("avi", "libxvid", "ac3_fixed"))
        return;
    if (tryCodecs("avi", "libxvid", "mp2"))
        return;
    if (tryCodecs("avi", "mpeg4", "libmp3lame"))
        return;
    if (tryCodecs("avi", "mpeg4", "ac3_fixed"))
        return;
    if (tryCodecs("avi", "mpeg4", "mp2"))
        return;

    // this shouldn't happen, just in case
    if (tryCodecs("ogg", "libtheora", "libvorbis"))
        return;
    tryCodecs("ogg", "libtheora", "flac");
}

void PageVideos::setDefaultOptions()
{
    framerateBox->setValue(25);
    checkRecordAudio->setChecked(true);
    checkUseGameRes->setChecked(true);
    setDefaultCodecs();
}

bool PageVideos::tryCodecs(const QString & format, const QString & vcodec, const QString & acodec)
{
    // first we should change format
    int iFormat = comboAVFormats->findData(format);
    if (iFormat == -1)
        return false;
    comboAVFormats->setCurrentIndex(iFormat);

    // try to find video codec
    int iVCodec = comboVideoCodecs->findData(vcodec);
    if (iVCodec == -1)
        return false;
    comboVideoCodecs->setCurrentIndex(iVCodec);

    // try to find audio codec
    int iACodec = comboAudioCodecs->findData(acodec);
    if (iACodec == -1 && checkRecordAudio->isChecked())
        return false;
    if (iACodec != -1)
        comboAudioCodecs->setCurrentIndex(iACodec);

    return true;
}

// get file size as string
QString FileSizeStr(const QString & path)
{
    quint64 size = QFileInfo(path).size();

    quint64 KiB = 1024;
    quint64 MiB = 1024*KiB;
    quint64 GiB = 1024*MiB;
    QString sizeStr;
    if (size >= GiB)
        return QString("%1 GiB").arg(QString::number(float(size)/GiB, 'f', 2));
    if (size >= MiB)
        return QString("%1 MiB").arg(QString::number(float(size)/MiB, 'f', 2));
     if (size >= KiB)
        return QString("%1 KiB").arg(QString::number(float(size)/KiB, 'f', 2));
    return PageVideos::tr("%1 bytes").arg(QString::number(size));
}

// set file size in file list in specified row
void PageVideos::updateSize(int row)
{
    VideoItem * item = nameItem(row);
    QString path = item->ready()? item->path() : cfgdir->absoluteFilePath("VideoTemp/" + item->pRecorder->name);
    filesTable->item(row, vcSize)->setText(FileSizeStr(path));
}

void PageVideos::updateFileList(const QString & path)
{
    // mark all files as non seen
    int numRows = filesTable->rowCount();
    for (int i = 0; i < numRows; i++)
        nameItem(i)->seen = false;

    QStringList files = QDir(path).entryList(QDir::Files);
    foreach (const QString & name, files)
    {
        int row = -1;
        foreach (QTableWidgetItem * item, filesTable->findItems(name, Qt::MatchExactly))
        {
            if (item->type() != QTableWidgetItem::UserType || !((VideoItem*)item)->ready())
                continue;
            row = item->row();
            break;
        }
        if (row == -1)
            row = appendRow(name);
        VideoItem * item = nameItem(row);
        item->seen = true;
        item->desc = "";
        updateSize(row);
    }

    // remove all non seen files
    for (int i = 0; i < filesTable->rowCount();)
    {
        VideoItem * item = nameItem(i);
        if (item->ready() && !item->seen)
            filesTable->removeRow(i);
        else
            i++;
    }
}

void PageVideos::addRecorder(HWRecorder* pRecorder)
{
    int row = appendRow(pRecorder->name);
    VideoItem * item = nameItem(row);
    item->pRecorder = pRecorder;
    pRecorder->item = item;

    // add progress bar
    QProgressBar * progressBar = new QProgressBar(filesTable);
    progressBar->setMinimum(0);
    progressBar->setMaximum(10000);
    progressBar->setValue(0);
    connect(pRecorder, SIGNAL(onProgress(float)), this, SLOT(updateProgress(float)));
    connect(pRecorder, SIGNAL(encodingFinished(bool)), this, SLOT(encodingFinished(bool)));
    filesTable->setCellWidget(row, vcProgress, progressBar);

    numRecorders++;
}

void PageVideos::updateProgress(float value)
{
    HWRecorder * pRecorder = (HWRecorder*)sender();
    VideoItem * item = (VideoItem*)pRecorder->item;
    int row = filesTable->row(item);

    // update file size every percent
    if (value - item->lastSizeUpdate > 0.01)
    {
        updateSize(row);
        item->lastSizeUpdate = value;
    }

    // update progress bar
    QProgressBar * progressBar = (QProgressBar*)filesTable->cellWidget(row, vcProgress);
    progressBar->setValue(value*10000);
    progressBar->setFormat(QString("%1%").arg(value*100, 0, 'f', 2));
    item->progress = value;
}

void PageVideos::encodingFinished(bool success)
{
    numRecorders--;

    HWRecorder * pRecorder = (HWRecorder*)sender();
    VideoItem * item = (VideoItem*)pRecorder->item;
    int row = filesTable->row(item);

    if (success)
    {
        // move file to destination
        success = cfgdir->rename("VideoTemp/" + pRecorder->name, "Videos/" + item->name);
        if (!success)
        {
            // unable to rename for some reason (maybe user entered incorrect name);
            // try to use temp name instead.
            success = cfgdir->rename("VideoTemp/" + pRecorder->name, "Videos/" + pRecorder->name);
            if (success)
                setName(item, pRecorder->name);
        }
    }

    if (!success)
    {
        filesTable->removeRow(row);
        return;
    }

    filesTable->setCellWidget(row, vcProgress, NULL); // remove progress bar
    item->pRecorder = NULL;
    updateSize(row);
    updateDescription();
}

void PageVideos::cellDoubleClicked(int row, int column)
{
    play(row);
}

void PageVideos::cellChanged(int row, int column)
{
    // user can only edit name
    if (column != vcName || nameChangedFromCode)
        return;

    // user has edited filename, so we should rename the file
    VideoItem * item = nameItem(row);
    QString oldName = item->name;
    QString newName = item->text();
    if (!newName.contains('.'))
    {
        // user forgot an extension
        int pt = oldName.lastIndexOf('.');
        if (pt != -1)
            newName += oldName.right(oldName.length() - pt);
    }
    item->name = newName;
    if (item->ready())
    {
        if(cfgdir->rename("Videos/" + oldName, "Videos/" + newName))
            updateDescription();
        else
        {
            // unable to rename for some reason (maybe user entered incorrect name),
            // therefore restore old name in cell
            setName(item, oldName);
        }
    }
    updateDescription();
}

void PageVideos::setName(VideoItem * item, const QString & newName)
{
    nameChangedFromCode = true;
    item->setText(newName);
    nameChangedFromCode = false;
    item->name = newName;
}

int PageVideos::appendRow(const QString & name)
{
    int row = filesTable->rowCount();
    filesTable->setRowCount(row+1);

    // add 'name' item
    QTableWidgetItem * item = new VideoItem(name);
    item->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable | Qt::ItemIsEditable);
    nameChangedFromCode = true;
    filesTable->setItem(row, vcName, item);
    nameChangedFromCode = false;

    // add 'size' item
    item = new QTableWidgetItem();
    item->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable);
    item->setTextAlignment(Qt::AlignRight);
    filesTable->setItem(row, vcSize, item);

    // add 'progress' item
    item = new QTableWidgetItem();
    item->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable);
    filesTable->setItem(row, vcProgress, item);

    return row;
}

VideoItem* PageVideos::nameItem(int row)
{
    return (VideoItem*)filesTable->item(row, vcName);
}

void PageVideos::updateDescription()
{
    VideoItem * item = nameItem(filesTable->currentRow());
    if (!item)
    {
        labelDesc->clear();
        labelThumbnail->clear();
        return;
    }

    QString desc = "";
    desc += item->name + "\n";

    QString thumbName = "";

    if (item->ready())
    {
        QString path = item->path();
        desc += tr("\nSize: ") + FileSizeStr(path) + "\n";
        if (item->desc == "")
            item->desc = LibavIteraction::instance().getFileInfo(path);
        desc += item->desc;

        // extract thumbnail name fron description
        int prefixBegin = desc.indexOf("prefix[");
        int prefixEnd = desc.indexOf("]prefix");
        if (prefixBegin != -1 && prefixEnd != -1)
        {
            QString prefix = desc.mid(prefixBegin + 7, prefixEnd - (prefixBegin + 7));
            desc.remove(prefixBegin, prefixEnd + 7 - prefixBegin);
            thumbName = prefix;
        }
    }
    else
        desc += tr("(in progress...)");

    if (thumbName.isEmpty())
    {
        if (item->ready())
            thumbName = item->name;
        else
            thumbName = item->pRecorder->name;
        // remove extension
        int pt = thumbName.lastIndexOf('.');
        if (pt != -1)
            thumbName.truncate(pt);
    }

    if (!thumbName.isEmpty())
    {
        thumbName = cfgdir->absoluteFilePath("VideoTemp/" + thumbName);
        if (picThumbnail.load(thumbName + ".png") || picThumbnail.load(thumbName + ".bmp"))
        {
            if (picThumbnail.width() > picThumbnail.height())
                picThumbnail = picThumbnail.scaledToWidth(ThumbnailSize);
            else
                picThumbnail = picThumbnail.scaledToHeight(ThumbnailSize);
            labelThumbnail->setMaximumSize(picThumbnail.size());
            labelThumbnail->setPixmap(picThumbnail);
        }
        else
            labelThumbnail->clear();
    }
    labelDesc->setText(desc);
}

// user selected another cell, so we should change description
void PageVideos::currentCellChanged(int row, int column, int previousRow, int previousColumn)
{
    updateDescription();
}

// open video file in external media player
void PageVideos::play(int row)
{
    VideoItem * item = nameItem(row);
    if (item->ready())
        QDesktopServices::openUrl(QUrl("file:///" + item->path()));
}

void PageVideos::playSelectedFile()
{
    int index = filesTable->currentRow();
    if (index != -1)
        play(index);
}

void PageVideos::deleteSelectedFiles()
{
    QList<QTableWidgetItem*> items = filesTable->selectedItems();
    int num = items.size() / vcNumColumns;
    if (num == 0)
        return;

    // ask user if (s)he is serious
    if (QMessageBox::question(this,
                              tr("Are you sure?"),
                              tr("Do you really want do remove %1 file(s)?").arg(num),
                              QMessageBox::Yes | QMessageBox::No)
            != QMessageBox::Yes)
        return;

    // remove
    foreach (QTableWidgetItem * witem, items)
    {
        if (witem->type() != QTableWidgetItem::UserType)
            continue;
        VideoItem * item = (VideoItem*)witem;
        if (!item->ready())
            item->pRecorder->deleteLater();
        else
            cfgdir->remove("Videos/" + item->name);
    }
}

void PageVideos::keyPressEvent(QKeyEvent * pEvent)
{
    if (filesTable->hasFocus())
    {
        if (pEvent->key() == Qt::Key_Delete)
        {
            deleteSelectedFiles();
            return;
        }
        if (pEvent->key() == Qt::Key_Enter) // doesn't work
        {
            playSelectedFile();
            return;
        }
    }
    AbstractPage::keyPressEvent(pEvent);
}

void PageVideos::openVideosDirectory()
{
    QDesktopServices::openUrl(QUrl("file:///"+cfgdir->absolutePath() + "/Videos"));
}

bool PageVideos::tryQuit(HWForm * form)
{
    if (numRecorders == 0)
        return true;

    // ask user what to do - abort or wait
    HWAskQuitDialog * askd = new HWAskQuitDialog(this, form);
    bool answer = askd->exec();
    delete askd;
    return answer;
}

// returns multi-line string with list of videos in progress
QString PageVideos::getVideosInProgress()
{
    QString list = "";
    int count = filesTable->rowCount();
    for (int i = 0; i < count; i++)
    {
        VideoItem * item = nameItem(i);
        float progress = 100*item->progress;
        if (progress > 99.99)
            progress = 99.99; // displaying 100% may be confusing
        if (!item->ready())
            list += item->name + " (" + QString::number(progress, 'f', 2) + "%)\n";
    }
    return list;
}
