/* borrowed from https://github.com/skhaz/qt-physfs-wrapper
 * TODO: add copyright header, determine license
 */

#include "FileEngine.h"
#include "hwpacksmounter.h"


const QString FileEngineHandler::scheme = "physfs:/";

FileEngine::FileEngine(const QString& filename)
    : m_handle(NULL)
    , m_size(0)
    , m_flags(0)
    , m_bufferSet(false)
    , m_readWrite(false)
{
    setFileName(filename);
}

FileEngine::~FileEngine()
{
    close();
}

bool FileEngine::open(QIODevice::OpenMode openMode)
{
    close();

    if ((openMode & QIODevice::ReadWrite) == QIODevice::ReadWrite) {
        m_handle = PHYSFS_openAppend(m_fileName.toUtf8().constData());
        if(m_handle)
        {
            m_readWrite = true;
            seek(0);
        }
    }

    else if (openMode & QIODevice::WriteOnly) {
        m_handle = PHYSFS_openWrite(m_fileName.toUtf8().constData());
        m_flags = QAbstractFileEngine::WriteOwnerPerm | QAbstractFileEngine::WriteUserPerm | QAbstractFileEngine::FileType;
    }

    else if (openMode & QIODevice::ReadOnly) {
        m_handle = PHYSFS_openRead(m_fileName.toUtf8().constData());
    }

    else if (openMode & QIODevice::Append) {
        m_handle = PHYSFS_openAppend(m_fileName.toUtf8().constData());
    }

    else {
        qWarning("[PHYSFS] Bad file open mode: %d", (int)openMode);
    }

    if (!m_handle) {
        qWarning("%s", QString("[PHYSFS] Failed to open %1, reason: %2").arg(m_fileName).arg(FileEngineHandler::errorStr()).toLocal8Bit().constData());
        return false;
    }

    return true;
}

bool FileEngine::close()
{
    if (isOpened()) {
        int result = PHYSFS_close(m_handle);
        m_handle = NULL;
        return result != 0;
    }

    return true;
}

bool FileEngine::flush()
{
    return PHYSFS_flush(m_handle) != 0;
}

qint64 FileEngine::size() const
{
    return m_size;
}

qint64 FileEngine::pos() const
{
    return PHYSFS_tell(m_handle);
}

bool FileEngine::setSize(qint64 size)
{
    if(size == 0)
    {
        m_size = 0;
        return open(QIODevice::WriteOnly);
    }
    else
        return false;
}

bool FileEngine::seek(qint64 pos)
{
    bool ok = PHYSFS_seek(m_handle, pos) != 0;

    return ok;
}

bool FileEngine::isSequential() const
{
    return false;
}

bool FileEngine::remove()
{
    return PHYSFS_delete(m_fileName.toUtf8().constData()) != 0;
}

bool FileEngine::mkdir(const QString &dirName, bool createParentDirectories) const
{
    Q_UNUSED(createParentDirectories);

    return PHYSFS_mkdir(dirName.toUtf8().constData()) != 0;
}

bool FileEngine::rmdir(const QString &dirName, bool recurseParentDirectories) const
{
    Q_UNUSED(recurseParentDirectories);

    return PHYSFS_delete(dirName.toUtf8().constData()) != 0;
}

bool FileEngine::caseSensitive() const
{
    return true;
}

bool FileEngine::isRelativePath() const
{
    return false;
}

QAbstractFileEngineIterator * FileEngine::beginEntryList(QDir::Filters filters, const QStringList &filterNames)
{
    return new FileEngineIterator(filters, filterNames, entryList(filters, filterNames));
}

QStringList FileEngine::entryList(QDir::Filters filters, const QStringList &filterNames) const
{
    Q_UNUSED(filters);

    QString file;
    QStringList result;
    char **files = PHYSFS_enumerateFiles(m_fileName.toUtf8().constData());

    for (char **i = files; *i != NULL; i++) {
        file = QString::fromUtf8(*i);

        if (filterNames.isEmpty() || QDir::match(filterNames, file)) {
            result << file;
        }
    }

    PHYSFS_freeList(files);

    return result;
}

QAbstractFileEngine::FileFlags FileEngine::fileFlags(FileFlags type) const
{
    return type & m_flags;
}

QString FileEngine::fileName(FileName file) const
{
    switch(file)
    {
        case QAbstractFileEngine::AbsolutePathName:
        {
            QString s(PHYSFS_getWriteDir());
            return s;
        }
        case QAbstractFileEngine::BaseName:
        {
            int l = m_fileName.lastIndexOf('/');
            QString s = m_fileName.mid(l + 1);
            return s;
        }
        case QAbstractFileEngine::DefaultName:
        case QAbstractFileEngine::AbsoluteName:
        default:
        {
            QString s = "physfs:/" + m_fileName;
            return s;
        }
    }
}

QDateTime FileEngine::fileTime(FileTime time) const
{
    switch (time)
    {
        case QAbstractFileEngine::ModificationTime:
        default:
            return m_date;
            break;
    };
}

void FileEngine::setFileName(const QString &file)
{
    if(file.startsWith(FileEngineHandler::scheme))
        m_fileName = file.mid(FileEngineHandler::scheme.size());
    else
        m_fileName = file;
    PHYSFS_Stat stat;
    if (PHYSFS_stat(m_fileName.toUtf8().constData(), &stat) != 0) {
        m_size = stat.filesize;
        m_date = QDateTime::fromTime_t(stat.modtime);
//        m_flags |= QAbstractFileEngine::WriteOwnerPerm;
        m_flags |= QAbstractFileEngine::ReadOwnerPerm;
        m_flags |= QAbstractFileEngine::ReadUserPerm;
        m_flags |= QAbstractFileEngine::ExistsFlag;
        m_flags |= QAbstractFileEngine::LocalDiskFlag;

        switch (stat.filetype)
        {
            case PHYSFS_FILETYPE_REGULAR:
                m_flags |= QAbstractFileEngine::FileType;
                break;
            case PHYSFS_FILETYPE_DIRECTORY:
                m_flags |= QAbstractFileEngine::DirectoryType;
                break;
            case PHYSFS_FILETYPE_SYMLINK:
                m_flags |= QAbstractFileEngine::LinkType;
                break;
            default: ;
        }
    }
}

bool FileEngine::atEnd() const
{
    return PHYSFS_eof(m_handle) != 0;
}

qint64 FileEngine::read(char *data, qint64 maxlen)
{
    if(m_readWrite)
    {
        if(pos() == 0)
            open(QIODevice::ReadOnly);
        else
            return -1;
    }

    qint64 len = PHYSFS_readBytes(m_handle, data, maxlen);
    return len;
}

qint64 FileEngine::readLine(char *data, qint64 maxlen)
{
    if(!m_bufferSet)
    {
        PHYSFS_setBuffer(m_handle, 4096);
        m_bufferSet = true;
    }

    qint64 bytesRead = 0;
    while(PHYSFS_readBytes(m_handle, data, 1)
          && maxlen
          && (*data == '\n'))
    {
        ++data;
        --maxlen;
        ++bytesRead;
    }

    return bytesRead;
}

qint64 FileEngine::write(const char *data, qint64 len)
{
    return PHYSFS_writeBytes(m_handle, data, len);
}

bool FileEngine::isOpened() const
{
    return m_handle != NULL;
}

QFile::FileError FileEngine::error() const
{
    return QFile::UnspecifiedError;
}

QString FileEngine::errorString() const
{
#if PHYSFS_VER_MAJOR >= 3
    return PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode());
#else
    return PHYSFS_getLastError();
#endif
}

bool FileEngine::supportsExtension(Extension extension) const
{
    return
            (extension == QAbstractFileEngine::AtEndExtension)
            || (extension == QAbstractFileEngine::FastReadLineExtension)
            ;
}


FileEngineHandler::FileEngineHandler(char *argv0)
{
    if (!PHYSFS_init(argv0))
    {
        qDebug("PHYSFS initialization failed");
    }
    qDebug("%s", QString("[PHYSFS] Init: %1").arg(errorStr()).toLocal8Bit().constData());
}

FileEngineHandler::~FileEngineHandler()
{
    PHYSFS_deinit();
}

QAbstractFileEngine* FileEngineHandler::create(const QString &filename) const
{
    if (filename.startsWith(scheme))
        return new FileEngine(filename);
    else
        return NULL;
}

void FileEngineHandler::mount(const QString &path)
{
    PHYSFS_mount(path.toUtf8().constData(), NULL, 0);
    qDebug("%s", QString("[PHYSFS] Mounting '%1' to '/': %2").arg(path).arg(errorStr()).toLocal8Bit().constData());
}

void FileEngineHandler::mount(const QString & path, const QString & mountPoint)
{
    PHYSFS_mount(path.toUtf8().constData(), mountPoint.toUtf8().constData(), 0);
    qDebug("%s", QString("[PHYSFS] Mounting '%1' to '%2': %3").arg(path).arg(mountPoint).arg(errorStr()).toLocal8Bit().data());
}

void FileEngineHandler::setWriteDir(const QString &path)
{
    PHYSFS_setWriteDir(path.toUtf8().constData());
    qDebug("%s", QString("[PHYSFS] Setting write dir to '%1': %2").arg(path).arg(errorStr()).toLocal8Bit().data());
}

void FileEngineHandler::mountPacks()
{
    hedgewarsMountPackages();
}

QString FileEngineHandler::errorStr()
{
    QString s;
#if PHYSFS_VER_MAJOR >= 3
    s = QString::fromUtf8(PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode()));
#else
    s = QString::fromUtf8(PHYSFS_getLastError());
#endif
    return s.isEmpty() ? "ok" : s;
}


FileEngineIterator::FileEngineIterator(QDir::Filters filters, const QStringList &nameFilters, const QStringList &entries)
    : QAbstractFileEngineIterator(filters, nameFilters)
{
    m_entries = entries;

    /* heck.. docs are unclear on this
     * QDirIterator puts iterator before first entry
     * but QAbstractFileEngineIterator example puts iterator on first entry
     * though QDirIterator approach seems to be the right one
     */

    m_index = -1;
}

bool FileEngineIterator::hasNext() const
{
    return m_index < m_entries.size() - 1;
}

QString FileEngineIterator::next()
{
   if (!hasNext())
       return QString();

   ++m_index;
   return currentFilePath();
}

QString FileEngineIterator::currentFileName() const
{
    return m_entries.at(m_index);
}
