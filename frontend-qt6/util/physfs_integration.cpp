#include "physfs_integration.h"

#include <QDebug>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>

#include "hwpacksmounter.h"

PhysFsFile::PhysFsFile(const QString &filename, QObject *parent)
    : QIODevice(parent), m_filename(filename), m_fileHandle(nullptr) {}

PhysFsFile::~PhysFsFile() { close(); }

bool PhysFsFile::open(OpenMode mode) {
  if (mode & QIODevice::ReadOnly) {
    m_fileHandle = PHYSFS_openRead(m_filename.toUtf8().constData());
  } else if (mode & QIODevice::WriteOnly) {
    if (mode & QIODevice::Append) {
      m_fileHandle = PHYSFS_openAppend(m_filename.toUtf8().constData());
    } else {
      m_fileHandle = PHYSFS_openWrite(m_filename.toUtf8().constData());
    }
  }

  if (!m_fileHandle) {
    setErrorString(
        QString::fromUtf8(PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
    return false;
  }

  return QIODevice::open(mode);
}

void PhysFsFile::close() {
  if (m_fileHandle) {
    PHYSFS_close(m_fileHandle);
    m_fileHandle = nullptr;
  }
  QIODevice::close();
}

qint64 PhysFsFile::size() const {
  return m_fileHandle ? PHYSFS_fileLength(m_fileHandle) : 0;
}

qint64 PhysFsFile::pos() const {
  return m_fileHandle ? PHYSFS_tell(m_fileHandle) : 0;
}

bool PhysFsFile::seek(qint64 pos) {
  if (!m_fileHandle) return false;
  if (PHYSFS_seek(m_fileHandle, pos) == 0) {
    return false;
  }
  return QIODevice::seek(pos);
}

bool PhysFsFile::isSequential() const {
  return false;  // PhysFS supports seeking
}

qint64 PhysFsFile::readData(char *data, qint64 maxlen) {
  if (!m_fileHandle) return -1;
  qint64 read = PHYSFS_readBytes(m_fileHandle, data, maxlen);
  if (read == -1) {
    setErrorString(
        QString::fromUtf8(PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
  }
  return read;
}

qint64 PhysFsFile::writeData(const char *data, qint64 len) {
  if (!m_fileHandle) return -1;
  qint64 written = PHYSFS_writeBytes(m_fileHandle, data, len);
  if (written == -1) {
    setErrorString(
        QString::fromUtf8(PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
  }
  return written;
}

PhysFsManager &PhysFsManager::instance() {
  static PhysFsManager instance;
  return instance;
}

bool PhysFsManager::init(const char *argv0) {
  if (PHYSFS_init(argv0) == 0) {
    qCritical() << "PhysFS Init Failed:" << getLastError();
    return false;
  }
  return true;
}

void PhysFsManager::deinit() { PHYSFS_deinit(); }

bool PhysFsManager::mount(const QString &archivePath, const QString &mountPoint,
                          bool appendToPath) {
  int res = PHYSFS_mount(
      archivePath.toUtf8().constData(),
      mountPoint.isEmpty() ? nullptr : mountPoint.toUtf8().constData(),
      appendToPath ? 1 : 0);
  return res != 0;
}

bool PhysFsManager::setWriteDir(const QString &path) {
  return PHYSFS_setWriteDir(path.toUtf8().constData()) != 0;
}

void PhysFsManager::mountPacks() { hedgewarsMountPackages(); }

bool PhysFsManager::exists(const QString &path) const {
  return PHYSFS_exists(path.toUtf8().constData());
}

bool PhysFsManager::isDirectory(const QString &path) const {
  PHYSFS_Stat stat;
  if (PHYSFS_stat(path.toUtf8().constData(), &stat) == 0) return false;
  return stat.filetype == PHYSFS_FILETYPE_DIRECTORY;
}

QStringList PhysFsManager::listDirectory(const QString &path) const {
  QStringList list;
  char **rc = PHYSFS_enumerateFiles(path.toUtf8().constData());

  if (rc) {
    for (char **i = rc; *i != nullptr; i++) {
      list << QString::fromUtf8(*i);
    }
    PHYSFS_freeList(rc);
  }
  return list;
}

QByteArray PhysFsManager::readFile(const QString &path) {
  PhysFsFile file(path);
  if (!file.open(QIODevice::ReadOnly)) {
    qWarning() << "Failed to read file:" << path << file.errorString();
    return QByteArray();
  }
  return file.readAll();
}

bool PhysFsManager::writeFile(const QString &path, const QByteArray &data) {
  PhysFsFile file(path);
  if (!file.open(QIODevice::WriteOnly)) {
    qWarning() << "Failed to write file:" << path << file.errorString();
    return false;
  }
  return file.write(data) == data.size();
}

QString PhysFsManager::getRealDir(const QString &filename) const {
  const auto realDir = PHYSFS_getRealDir(filename.toUtf8().constData());
  return (realDir == nullptr) ? QString{} : QString::fromUtf8(realDir);
}

// ----------------------------------------------------------------------------
// Handling Settings
// ----------------------------------------------------------------------------
// Standard QSettings expects a native file path or registry.
// When using PhysFS, we usually want settings in the WriteDir (e.g. SaveGame
// folder). It is cleaner to serialize a QVariantMap to JSON and store it via
// PhysFS.

bool PhysFsManager::saveSettings(const QString &filename,
                                 const QVariantMap &settings) {
  QJsonObject jsonObject = QJsonObject::fromVariantMap(settings);
  QJsonDocument doc(jsonObject);
  return writeFile(filename, doc.toJson());
}

QVariantMap PhysFsManager::loadSettings(const QString &filename) {
  QByteArray data = readFile(filename);
  if (data.isEmpty()) return QVariantMap();

  QJsonDocument doc = QJsonDocument::fromJson(data);
  return doc.object().toVariantMap();
}

QString PhysFsManager::getLastError() const {
  return QString::fromUtf8(PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode()));
}
