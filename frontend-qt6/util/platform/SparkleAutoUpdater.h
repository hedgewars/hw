/*
 * Copyright (C) 2008 Remko Troncon
 */

#ifndef SPARKLEAUTOUPDATER_H
#define SPARKLEAUTOUPDATER_H

#include <QString>

#include "AutoUpdater.h"

class SparkleAutoUpdater : public AutoUpdater {
 public:
  SparkleAutoUpdater();
  SparkleAutoUpdater(const SparkleAutoUpdater &) = delete;
  SparkleAutoUpdater(SparkleAutoUpdater &&) = delete;
  SparkleAutoUpdater &operator=(const SparkleAutoUpdater &) = delete;
  SparkleAutoUpdater &operator=(SparkleAutoUpdater &&) = delete;
  ~SparkleAutoUpdater();

  void checkForUpdates() override;
  void checkForUpdatesNow() override;

 private:
  class Private;
  Private *d;
};

#endif
