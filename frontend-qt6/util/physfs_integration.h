#pragma once

#include <QByteArray>
#include <QIODevice>
#include <QObject>
#include <QStringList>
#include <QVariantMap>

#include "physfs.h"

class PhysFsFile : public QIODevice {
  Q_OBJECT

 public:
  explicit PhysFsFile(const QString &filename, QObject *parent = nullptr);
  ~PhysFsFile() override;

  bool open(OpenMode mode) override;
  void close() override;
  qint64 size() const override;
  qint64 pos() const override;
  bool seek(qint64 pos) override;
  bool isSequential() const override;

 protected:
  qint64 readData(char *data, qint64 maxlen) override;
  qint64 writeData(const char *data, qint64 len) override;

 private:
  QString m_filename;
  PHYSFS_File *m_fileHandle;
};

class PhysFsManager : public QObject {
  Q_OBJECT

 public:
  static PhysFsManager &instance();

  bool init(const char *argv0);
  void deinit();

  bool mount(const QString &archivePath, const QString &mountPoint = {},
             bool appendToPath = true);
  bool setWriteDir(const QString &path);
  void mountPacks();

  bool exists(const QString &path) const;
  bool isDirectory(const QString &path) const;
  QStringList listDirectory(const QString &path) const;
  QByteArray readFile(const QString &path);
  bool writeFile(const QString &path, const QByteArray &data);
  QString getRealDir(const QString &filename) const;

  bool saveSettings(const QString &filename, const QVariantMap &settings);
  QVariantMap loadSettings(const QString &filename);

  QString getLastError() const;

 private:
  PhysFsManager() = default;
  ~PhysFsManager() = default;

  Q_DISABLE_COPY_MOVE(PhysFsManager)
};
