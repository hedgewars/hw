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
#include <QDateTime>
#include <QRegExp>
#include <QXmlStreamReader>

#include "hwconsts.h"
#include "pagevideos.h"
#include "igbox.h"
#include "LibavInteraction.h"
#include "gameuiconfig.h"
#include "recorder.h"
#include "ask_quit.h"
#include "util/MessageDialog.h"

static const QSize ThumbnailSize(350, 350*3/5);

// columns in table with list of video files
enum VideosColumns
{
    vcName,
    vcSize,
    vcProgress, // for encoding

    vcNumColumns,
};

// this class is used for items in first column in file-table
class VideoItem : public QTableWidgetItem
{
    // note: QTableWidgetItem is not Q_OBJECT

    public:
        VideoItem(const QString& name);
        ~VideoItem();

        QString name;
        QString prefix; // original filename without extension
        QString desc;   // description (duration, resolution, etc...)
        HWRecorder    * pRecorder; // non NULL if file is being encoded
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
    seen = false;
}

VideoItem::~VideoItem()
{}

QLayout * PageVideos::bodyLayoutDefinition()
{
    QGridLayout * pPageLayout = new QGridLayout();
    pPageLayout->setColumnStretch(0, 1);
    pPageLayout->setColumnStretch(1, 2);

    // list of videos
    {
        IconedGroupBox* pTableGroup = new IconedGroupBox(this);
        pTableGroup->setIcon(QIcon(":/res/Videos.png"));
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
        filesTable->setSelectionMode(QAbstractItemView::SingleSelection);
        filesTable->setEditTriggers(QAbstractItemView::SelectedClicked);
        filesTable->setShowGrid(false);
        filesTable->setAlternatingRowColors(true);
        filesTable->verticalHeader()->hide();
        filesTable->setMinimumWidth(400);

        QHeaderView * header = filesTable->horizontalHeader();
        header->setSectionResizeMode(vcName, QHeaderView::ResizeToContents);
        header->setSectionResizeMode(vcSize, QHeaderView::Fixed);
        header->resizeSection(vcSize, 100);
        header->setStretchLastSection(true);

        btnOpenDir = new QPushButton(QPushButton::tr("Open videos directory"), pTableGroup);
        btnOpenDir->setWhatsThis(QPushButton::tr("Open the video directory in your system"));

        QVBoxLayout *box = new QVBoxLayout(pTableGroup);
        box->addWidget(filesTable);
        box->addWidget(btnOpenDir);

        pPageLayout->addWidget(pTableGroup, 0, 1);
    }

    // description
    {
        IconedGroupBox* pDescGroup = new IconedGroupBox(this);
        pDescGroup->setIcon(QIcon(":/res/miscicon.png"));
        pDescGroup->setTitle(QGroupBox::tr("Description"));

        QVBoxLayout* pDescLayout = new QVBoxLayout(pDescGroup);
        QHBoxLayout* pBottomDescLayout = new QHBoxLayout(0); // buttons

        // label with thumbnail picture
        labelThumbnail = new QLabel(pDescGroup);
        labelThumbnail->setAlignment(Qt::AlignHCenter | Qt::AlignVCenter);
        labelThumbnail->setMaximumSize(ThumbnailSize);
        labelThumbnail->setStyleSheet(
                    "QFrame {"
                    "border: solid;"
                    "border-width: 3px;"
                    "border-color: #ffcc00;"
                    "border-radius: 4px;"
                    "}" );
        clearThumbnail();

        // label with file description
        labelDesc = new QLabel(pDescGroup);
        labelDesc->setAlignment(Qt::AlignLeft | Qt::AlignTop);
        labelDesc->setTextInteractionFlags(Qt::TextSelectableByMouse |
                                           Qt::TextSelectableByKeyboard |
                                           Qt::LinksAccessibleByMouse |
                                           Qt::LinksAccessibleByKeyboard);
        labelDesc->setTextFormat(Qt::PlainText);
        labelDesc->setWordWrap(true);
        labelDesc->setOpenExternalLinks(false);

        // buttons: play and delete
        btnPlay = new QPushButton(QPushButton::tr("Play"), pDescGroup);
        btnPlay->setEnabled(false);
        btnPlay->setWhatsThis(QPushButton::tr("Play this video"));
        pBottomDescLayout->addWidget(btnPlay);
        btnDelete = new QPushButton(QPushButton::tr("Delete"), pDescGroup);
        btnDelete->setEnabled(false);
        btnDelete->setWhatsThis(QPushButton::tr("Delete this video"));
        pBottomDescLayout->addWidget(btnDelete);

        pDescLayout->addWidget(labelThumbnail, 0);
        pDescLayout->addWidget(labelDesc, 0);
        pDescLayout->addLayout(pBottomDescLayout, 0);
        pDescLayout->addStretch(1);

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
    connect(filesTable, SIGNAL(cellDoubleClicked(int, int)), this, SLOT(cellDoubleClicked(int, int)));
    connect(filesTable, SIGNAL(cellChanged(int,int)), this, SLOT(cellChanged(int, int)));
    connect(filesTable, SIGNAL(currentCellChanged(int,int,int,int)), this, SLOT(currentCellChanged()));
    connect(btnPlay,   SIGNAL(clicked()), this, SLOT(playSelectedFile()));
    connect(btnDelete, SIGNAL(clicked()), this, SLOT(deleteSelectedFiles()));
    connect(btnOpenDir, SIGNAL(clicked()), this, SLOT(openVideosDirectory()));
}

PageVideos::PageVideos(QWidget* parent) : AbstractPage(parent),
    config(0)
{
    nameChangedFromCode = false;
    numRecorders = 0;
    // Clear VideoTemp at launch in case some garbage remained in here after a crash
    clearTemp();
    initPage();
}

void PageVideos::init(GameUIConfig * config)
{
    this->config = config;

    QString path = cfgdir->absolutePath() + "/Videos";
    QFileSystemWatcher * pWatcher = new QFileSystemWatcher(this);
    pWatcher->addPath(path);
    connect(pWatcher, SIGNAL(directoryChanged(const QString &)), this, SLOT(updateFileList(const QString &)));
    updateFileList(path);

    startEncoding(); // this is for videos recorded from demos which were executed directly (without frontend)
}

// get file size as string
static QString FileSizeStr(const QString & path)
{
    qint64 size = QFileInfo(path).size();

#if (QT_VERSION >= QT_VERSION_CHECK(5, 10, 0))
    return QLocale().formattedDataSize(size);
#else
    qint64 KiB = 1024;
    qint64 MiB = 1024*KiB;
    qint64 GiB = 1024*MiB;
    QString sizeStr;
    float fsize = (float) size;
    if (size >= GiB)
        return QString("%1 GiB").arg(QLocale().toString(fsize/GiB, 'f', 2));
    if (size >= MiB)
        return QString("%1 MiB").arg(QLocale().toString(fsize/MiB, 'f', 2));
    if (size >= KiB)
        return QString("%1 KiB").arg(QLocale().toString(fsize/KiB, 'f', 2));
    return PageVideos::tr("%1 bytes", "", size).arg(QString::number(size));
#endif
}

// set file size in file list in specified row
void PageVideos::updateSize(int row)
{
    VideoItem * item = nameItem(row);
    QString path = item->ready()? item->path() : cfgdir->absoluteFilePath("VideoTemp/" + item->pRecorder->name);
    filesTable->item(row, vcSize)->setText(FileSizeStr(path));
}

// There is a button 'Open videos dir', so it is possible that user will open
// this dir and rename/delete some files there, so we should handle this.
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
        setName(item, item->name);
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
    connect(pRecorder, SIGNAL(ErrorMessage(const QString &)), this, SLOT(ShowFatalErrorMessage(const QString &)), Qt::QueuedConnection);
    filesTable->setCellWidget(row, vcProgress, progressBar);

    numRecorders++;
}

void PageVideos::setProgress(int row, VideoItem* item, float value)
{
    QProgressBar * progressBar = (QProgressBar*)filesTable->cellWidget(row, vcProgress);
    progressBar->setValue(value*10000);
    //: Video encoding progress. %1 = number
    progressBar->setFormat(QString(tr("%1%")).arg(QLocale().toString(value*100, 'f', 2)));
    item->progress = value;
}

void PageVideos::updateProgress(float value)
{
    HWRecorder * pRecorder = (HWRecorder*)sender();
    VideoItem * item = pRecorder->item;
    int row = filesTable->row(item);

    // update file size every percent
    if (value - item->lastSizeUpdate > 0.01)
    {
        updateSize(row);
        item->lastSizeUpdate = value;
    }

    setProgress(row, item, value);
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
    Q_UNUSED(column);

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
    int pointPos = oldName.lastIndexOf('.');
    QString oldPrefix = item->name;
    oldPrefix.truncate(pointPos);
    QString newName = item->text();
    if (!newName.contains('.')) // user forgot an extension
    {
        // restore old extension
        pointPos = oldName.lastIndexOf('.');
        if (pointPos != -1)
        {
            newName += oldName.right(oldName.length() - pointPos);
            setName(item, newName);
        }
    }
    QString newPrefix;
    if (newName.contains('.'))
    {
        pointPos = newName.lastIndexOf('.');
        if (pointPos != -1)
        {
            newPrefix = newName;
            newPrefix.truncate(pointPos);
        }
    }
    else
        newPrefix = newName;
    for (int i = 0; i < filesTable->rowCount(); i++)
    {
        // don't allow rename if duplicate prefix
        VideoItem * iterateItem = nameItem(i);
        if ((i != row) && (newPrefix == iterateItem->prefix))
        {
            setName(item, oldName);
            return;
        }
    }
#ifdef Q_OS_WIN
    // there is a bug in qt, QDir::rename() doesn't fail on such names but damages files
    if (newName.contains(QRegExp("[\"*:<>?\\/|]")))
    {
        setName(item, oldName);
        return;
    }
#endif
    if (item->ready() && !cfgdir->rename("Videos/" + oldName, "Videos/" + newName))
    {
        // unable to rename for some reason (maybe user entered incorrect name),
        // therefore restore old name in cell
        setName(item, oldName);
        return;
    }
    if (item->ready())
    {
        cfgdir->rename("VideoThumbnails/" + oldPrefix + ".png", "VideoThumbnails/" + newPrefix + ".png");
        cfgdir->rename("VideoThumbnails/" + oldPrefix + ".bmp", "VideoThumbnails/" + newPrefix + ".bmp");
    }
    item->name = newName;
    item->prefix = newPrefix;
    updateDescription();
}

void PageVideos::setName(VideoItem * item, const QString & newName)
{
    nameChangedFromCode = true;
    item->setText(newName);
    nameChangedFromCode = false;
    item->name = newName;
    // try to extract prefix
    if (item->ready())
        item->prefix = item->name;
    else
        item->prefix = item->pRecorder->name;
    // remove extension
    int pt = item->prefix.lastIndexOf('.');
    if (pt != -1)
        item->prefix.truncate(pt);
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

void PageVideos::clearThumbnail()
{
    // add empty (transparent) image for proper sizing
    QPixmap pic(ThumbnailSize);
    pic.fill(QColor(0,0,0,0));
    labelThumbnail->setPixmap(pic);
}

void PageVideos::updateDescription()
{
    VideoItem * item = nameItem(filesTable->currentRow());
    if (!item)
    {
        // nothing is selected => clear description and return
        labelDesc->clear();
        clearThumbnail();
        btnPlay->setEnabled(false);
        btnDelete->setEnabled(false);
        return;
    }

    btnPlay->setEnabled(item->ready());
    btnDelete->setEnabled(true);
    btnDelete->setText(item->ready()? QPushButton::tr("Delete") :  QPushButton::tr("Cancel"));

    // construct string with desctiption of this file to display it
    QString desc = item->name + "\n\n";

    if (!item->ready())
        desc += tr("(in progress...)");
    else
    {
        QString path = item->path();
        desc += tr("Date: %1").arg(QFileInfo(path).created().toString(Qt::DefaultLocaleLongDate)) + "\n";
        desc += tr("Size: %1").arg(FileSizeStr(path)) + "\n";
        if (item->desc.isEmpty())
        {
            // Extract description from file;
            // It will contain duration, resolution, etc and also comment added by hwengine.
            item->desc = LibavInteraction::instance().getFileInfo(path);

            // extract prefix (original name) from description (it is enclosed in prefix[???]prefix)
            int prefixBegin = item->desc.indexOf("prefix[");
            int prefixEnd   = item->desc.indexOf("]prefix");
            if (prefixBegin != -1 && prefixEnd != -1)
            {
                item->prefix = item->desc.mid(prefixBegin + 7, prefixEnd - (prefixBegin + 7));
                item->desc.remove(prefixBegin, prefixEnd + 7 - prefixBegin);
            }
        }
        desc += item->desc + '\n';
    }

    if (item->prefix.isNull() || item->prefix.isEmpty())
    {
        // try to extract prefix from file name instead
        if (item->ready())
            item->prefix = item->name;
        else
            item->prefix = item->pRecorder->name;

        // remove extension
        int pt = item->prefix.lastIndexOf('.');
        if (pt != -1)
            item->prefix.truncate(pt);
    }

    labelDesc->setText(desc);

    if (!item->prefix.isEmpty())
    {
        QString thumbName = cfgdir->absoluteFilePath("VideoThumbnails/" + item->prefix);
        QPixmap pic;
        if (pic.load(thumbName + ".png") || pic.load(thumbName + ".bmp"))
        {
            if (pic.height()*ThumbnailSize.width() > pic.width()*ThumbnailSize.height())
                pic = pic.scaledToWidth(ThumbnailSize.width());
            else
                pic = pic.scaledToHeight(ThumbnailSize.height());
            labelThumbnail->setPixmap(pic);
        }
        else
            clearThumbnail();
    }
}

// user selected another cell, so we should change description
void PageVideos::currentCellChanged()
{
    updateDescription();
}

// open video file in external media player
void PageVideos::play(int row)
{
    VideoItem * item = nameItem(row);
    if (item && item->ready())
        QDesktopServices::openUrl(QUrl("file:///" + QDir::toNativeSeparators(item->path())));
}

void PageVideos::playSelectedFile()
{
    int index = filesTable->currentRow();
    if (index != -1)
        play(index);
}

void PageVideos::deleteSelectedFiles()
{
    int index = filesTable->currentRow();
    if (index == -1)
        return;

    VideoItem * item = nameItem(index);
    if (!item)
        return;

    // ask user if (s)he is serious
    QMessageBox reallyDeleteMsg(this);
    reallyDeleteMsg.setIcon(QMessageBox::Question);
    reallyDeleteMsg.setWindowTitle(QMessageBox::tr("Videos - Are you sure?"));
    reallyDeleteMsg.setText(QMessageBox::tr("Do you really want to delete the video '%1'?").arg(item->name));
    reallyDeleteMsg.setTextFormat(Qt::PlainText);
    reallyDeleteMsg.setWindowModality(Qt::WindowModal);
    reallyDeleteMsg.setStandardButtons(QMessageBox::Ok | QMessageBox::Cancel);

    if (reallyDeleteMsg.exec() != QMessageBox::Ok)
        return;

    // abort / remove
    if (!item->ready())
        item->pRecorder->abort();
    else
    {
        cfgdir->remove("Videos/" + item->name);
        // we have no idea whether screenshot is going to be bmp or png so let's delete both
        cfgdir->remove("VideoThumbnails/" + item->prefix + ".png");
        cfgdir->remove("VideoThumbnails/" + item->prefix + ".bmp");
    }

// this code is for removing several files when multiple selection is enabled
#if 0
    QList<QTableWidgetItem*> items = filesTable->selectedItems();
    int num = items.size() / vcNumColumns;
    if (num == 0)
        return;

    // ask user if (s)he is serious
    QMessageBox reallyDeleteMsg(this);
    reallyDeleteMsg.setIcon(QMessageBox::Question);
    reallyDeleteMsg.setWindowTitle(QMessageBox::tr("Videos - Are you sure?"));
    reallyDeleteMsg.setText(QMessageBox::tr("Do you really want to remove %1 file(s)?", "", num).arg(num));
    reallyDeleteMsg.setWindowModality(Qt::WindowModal);
    reallyDeleteMsg.setStandardButtons(QMessageBox::Ok | QMessageBox::Cancel);

    if (reallyDeleteMsg.exec() != QMessageBox::Ok)
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
#endif
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
    QString path = QDir::toNativeSeparators(cfgdir->absolutePath() + "/Videos");
    QDesktopServices::openUrl(QUrl("file:///" + path));
}

// clear VideoTemp directory
void PageVideos::clearTemp()
{
    qDebug("Clearing VideoTemp directory ...");
    QDir temp(cfgdir->absolutePath() + "/VideoTemp");
    QStringList files = temp.entryList(QDir::Files);
    foreach (const QString& file, files)
    {
        // Legacy support: Move thumbnails to correct dir
        if (file.endsWith(".bmp") || file.endsWith(".png"))
        {
            qDebug("Moving video thumbnail '%s' to VideoThumbnails directory", qPrintable(file));
            cfgdir->rename("VideoTemp/" + file, "VideoThumbnails/" + file);
        }
        else
            temp.remove(file);
    }
}

bool PageVideos::tryQuit(HWForm * form)
{
    bool quit = true;
    if (numRecorders != 0)
    {
        // ask user what to do - abort or wait
        HWAskQuitDialog * askd = new HWAskQuitDialog(this, form);
        askd->deleteLater();
        quit = askd->exec();
    }
    if (quit)
        clearTemp();
    return quit;
}

// returns multi-line string with list of videos in progress
/* it will look like this:
foo.avi (15.21% - encoding)
*/
QString PageVideos::getVideosInProgress()
{
    QString list = "";
    int count = filesTable->rowCount();
    for (int i = 0; i < count; i++)
    {
        VideoItem * item = nameItem(i);
        QString process;
        if (item->ready())
            continue;
        float progress = 100*item->progress;
        if (progress > 99.99)
            progress = 99.99; // displaying 100% may be confusing
        //: Video encoding list entry. %1 = file name, %2 = percent complete, %3 = video operation type (e.g. “encoding”)
        list += QString(tr("%1 (%2%) - %3"))
            .arg(item->name)
            .arg(QLocale().toString(progress, 'f', 2))
            .arg(tr("encoding"))
            + "\n";
    }
    return list;
}

void PageVideos::startEncoding(const QByteArray & record)
{
    QDir videoTempDir(cfgdir->absolutePath() + "/VideoTemp/");
    QStringList files = videoTempDir.entryList(QStringList("*.txtout"), QDir::Files);
    foreach (const QString & str, files)
    {
        QString prefix = str;
        prefix.chop(7); // remove ".txtout"
        videoTempDir.rename(prefix + ".txtout", prefix + ".txtin"); // rename this file to not open it twice

        HWRecorder* pRecorder = new HWRecorder(config, prefix);

        if (!record.isEmpty())
            pRecorder->EncodeVideo(record);
        else
        {
            // this is for videos recorded from demos which were executed directly (without frontend)
            QFile demofile(videoTempDir.absoluteFilePath(prefix + ".hwd"));
            if (!demofile.open(QIODevice::ReadOnly))
                continue;
            QByteArray demo = demofile.readAll();
            if (demo.isEmpty())
                continue;
            pRecorder->EncodeVideo(demo);
        }
        addRecorder(pRecorder);
    }
}

void PageVideos::ShowFatalErrorMessage(const QString & msg)
{
    MessageDialog::ShowFatalMessage(msg, this);
}

