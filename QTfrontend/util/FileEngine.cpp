/* borrowed from https://github.com/skhaz/qt-physfs-wrapper
 * TODO: add copyright header, determine license
 */

#include "hwpacksmounter.h"
#include "FileEngine.h"


const QString FileEngineHandler::scheme = "physfs:/";

FileEngine::FileEngine(const QString& filename)
: _handler(NULL)
, _flags(0)
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

    if (openMode & QIODevice::WriteOnly) {
        _handler = PHYSFS_openWrite(_filename.toUtf8().constData());
        _flags = QAbstractFileEngine::WriteOwnerPerm | QAbstractFileEngine::WriteUserPerm | QAbstractFileEngine::FileType;
    }

    else if (openMode & QIODevice::ReadOnly) {
        _handler = PHYSFS_openRead(_filename.toUtf8().constData());
    }

    else if (openMode & QIODevice::Append) {
        _handler = PHYSFS_openAppend(_filename.toUtf8().constData());
    }

    else {
        qWarning("Bad file open mode: %d", (int)openMode);
    }

    if (!_handler) {
        qWarning("Failed to open %s, reason: %s", _filename.toUtf8().constData(), PHYSFS_getLastError());
        return false;
    }

    return true;
}

bool FileEngine::close()
{
    if (isOpened()) {
        int result = PHYSFS_close(_handler);
        _handler = NULL;
        return result != 0;
    }

    return true;
}

bool FileEngine::flush()
{
    return PHYSFS_flush(_handler) != 0;
}

qint64 FileEngine::size() const
{
    return _size;
}

qint64 FileEngine::pos() const
{
    return PHYSFS_tell(_handler);
}

bool FileEngine::seek(qint64 pos)
{
    return PHYSFS_seek(_handler, pos) != 0;
}

bool FileEngine::isSequential() const
{
    return false;
}

bool FileEngine::remove()
{
    return PHYSFS_delete(_filename.toUtf8().constData()) != 0;
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
    return true;
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
    char **files = PHYSFS_enumerateFiles(_filename.toUtf8().constData());

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
    return type & _flags;
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
            int l = _filename.lastIndexOf('/');
            QString s = _filename.mid(l + 1);
            return s;
        }
        case QAbstractFileEngine::DefaultName:
        case QAbstractFileEngine::AbsoluteName:
        default:
        {
            QString s = "physfs:/" + _filename;
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
            return _datetime;
            break;
    };
}

void FileEngine::setFileName(const QString &file)
{
    if(file.startsWith(FileEngineHandler::scheme))
        _filename = file.mid(FileEngineHandler::scheme.size());
    else
        _filename = file;

    PHYSFS_Stat stat;
    if (PHYSFS_stat(_filename.toUtf8().constData(), &stat) != 0) {
        _size = stat.filesize;
        _datetime = QDateTime::fromTime_t(stat.modtime);
//        _flags |= QAbstractFileEngine::WriteUserPerm;
        _flags |= QAbstractFileEngine::ReadUserPerm;
        _flags |= QAbstractFileEngine::ExistsFlag;

        switch (stat.filetype)
        {
            case PHYSFS_FILETYPE_REGULAR:
                _flags |= QAbstractFileEngine::FileType;
                break;

            case PHYSFS_FILETYPE_DIRECTORY:
                _flags |= QAbstractFileEngine::DirectoryType;
                break;
            case PHYSFS_FILETYPE_SYMLINK:
                _flags |= QAbstractFileEngine::LinkType;
                break;
            default: ;
        }
    }
}

bool FileEngine::atEnd() const
{
    return PHYSFS_eof(_handler) != 0;
}

qint64 FileEngine::read(char *data, qint64 maxlen)
{
    return PHYSFS_readBytes(_handler, data, maxlen);
}

qint64 FileEngine::write(const char *data, qint64 len)
{
    return PHYSFS_writeBytes(_handler, data, len);
}

bool FileEngine::isOpened() const
{
    return _handler != NULL;
}

QFile::FileError FileEngine::error() const
{
    return QFile::UnspecifiedError;
}

QString FileEngine::errorString() const
{
    return PHYSFS_getLastError();
}

bool FileEngine::supportsExtension(Extension extension) const
{
    return extension == QAbstractFileEngine::AtEndExtension;
}



FileEngineHandler::FileEngineHandler(char *argv0)
{
    PHYSFS_init(argv0);
}

FileEngineHandler::~FileEngineHandler()
{
    PHYSFS_deinit();
}

QAbstractFileEngine* FileEngineHandler::create(const QString &filename) const
{
    if (filename.startsWith(scheme))
        return new FileEngine(filename.mid(scheme.size()));
    else
        return NULL;
}

void FileEngineHandler::mount(const QString &path)
{
    PHYSFS_mount(path.toUtf8().constData(), NULL, 1);
}

void FileEngineHandler::mount(const QString & path, const QString & mountPoint)
{
    PHYSFS_mount(path.toUtf8().constData(), mountPoint.toUtf8().constData(), 1);
}

void FileEngineHandler::setWriteDir(const QString &path)
{
    PHYSFS_setWriteDir(path.toUtf8().constData());
}

void FileEngineHandler::mountPacks()
{
    hedgewarsMountPackages();
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
