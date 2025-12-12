#include "physfs_integration.h"

#include <QDebug>
#include <QFileInfo>
#include <QIcon>
#include <QJsonDocument>
#include <QJsonObject>

#include "hwpacksmounter.h"

PhysFsFile::PhysFsFile(const QString &filename, QObject *parent)
    : QIODevice(parent), m_filename(filename), m_fileHandle(nullptr) {}

PhysFsFile::~PhysFsFile() { _close(); }

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

void PhysFsFile::close() { _close(); }

qint64 PhysFsFile::size() const {
  return m_fileHandle ? PHYSFS_fileLength(m_fileHandle) : 0;
}

qint64 PhysFsFile::pos() const {
  return m_fileHandle ? PHYSFS_tell(m_fileHandle) : 0;
}

bool PhysFsFile::seek(qint64 pos) {
  if (!m_fileHandle) {
    return false;
  }

  if (PHYSFS_seek(m_fileHandle, pos) == 0) {
    return false;
  }

  return QIODevice::seek(pos);
}

bool PhysFsFile::isSequential() const {
  return false;  // PhysFS supports seeking
}

bool PhysFsFile::exists() const {
  PHYSFS_Stat stat;
  if (PHYSFS_stat(m_filename.toUtf8().constData(), &stat) != 0) {
    return stat.filetype == PHYSFS_FILETYPE_REGULAR;
  }

  return false;
}

qint64 PhysFsFile::readData(char *data, qint64 maxlen) {
  if (!m_fileHandle) {
    return -1;
  }

  qint64 read = PHYSFS_readBytes(m_fileHandle, data, maxlen);

  if (read == -1) {
    setErrorString(
        QString::fromUtf8(PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
  }

  return read;
}

qint64 PhysFsFile::writeData(const char *data, qint64 len) {
  if (!m_fileHandle) {
    return -1;
  }

  qint64 written = PHYSFS_writeBytes(m_fileHandle, data, len);

  if (written == -1) {
    setErrorString(
        QString::fromUtf8(PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
  }

  return written;
}

void PhysFsFile::_close() {
  if (m_fileHandle) {
    PHYSFS_close(m_fileHandle);
    m_fileHandle = nullptr;
  }
  QIODevice::close();
}

PhysFsIniReader::PhysFsIniReader(const QString &filename, QObject *parent)
    : QObject{parent} {
  QByteArray data = PhysFsManager::instance().readFile(filename);

  if (!data.isEmpty()) {
    parse(QString::fromUtf8(data));
  }
}

void PhysFsIniReader::parse(const QString &content) {
  const auto lines = content.split(QRegularExpression(QStringLiteral("[\r\n]")),
                                   Qt::SkipEmptyParts);

  QString currentSection;
  for (QString line : lines) {
    line = line.trimmed();

    if (line.isEmpty() || line.startsWith('#') || line.startsWith(';')) {
      continue;
    }

    if (line.startsWith('[') && line.endsWith(']')) {
      currentSection = line.mid(1, line.length() - 2).trimmed();
      continue;
    }

    int equalsPos = line.indexOf('=');
    if (equalsPos != -1) {
      auto key = line.left(equalsPos).trimmed();
      auto valStr = line.mid(equalsPos + 1).trimmed();

      auto fullKey =
          currentSection.isEmpty() ? key : (currentSection + '/' + key);

      QVariant value;
      if (valStr.compare(QLatin1String("true"), Qt::CaseInsensitive) == 0) {
        value = true;
      } else if (valStr.compare(QLatin1String("false"), Qt::CaseInsensitive) ==
                 0) {
        value = false;
      } else
        value = valStr;  // Default to string

      m_values.insert(fullKey, value);
    }
  }
}

QVariant PhysFsIniReader::value(QAnyStringView key,
                                const QVariant &defaultValue) const {
  return m_values.value(key.toString(), defaultValue);
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

QByteArray PhysFsManager::readFile(const QString &path) const {
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

QImage PhysFsManager::readImage(const QString &path) const {
  QByteArray data = readFile(path);

  if (data.isEmpty()) {
    return {};
  }

  QImage image;
  if (!image.loadFromData(data)) {
    qWarning() << "Failed to decode icon from:" << path;
    return {};
  }

  return image;
}

QPixmap PhysFsManager::readPixmap(const QString &path) const {
  QByteArray data = readFile(path);

  if (data.isEmpty()) {
    return {};
  }

  QPixmap pix;
  if (!pix.loadFromData(data)) {
    qWarning() << "Failed to decode icon from:" << path;
    return {};
  }

  return pix;
}

QIcon PhysFsManager::readIcon(const QString &path) const {
  return QIcon{readPixmap(path)};
}

QString PhysFsManager::getLastError() const {
  return QString::fromUtf8(PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode()));
}
