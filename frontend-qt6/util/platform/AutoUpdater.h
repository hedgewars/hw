/*
 * Copyright (C) 2008 Remko Troncon
 */

#ifndef AUTOUPDATER_H
#define AUTOUPDATER_H

class AutoUpdater {
 public:
  AutoUpdater() = default;

  AutoUpdater(const AutoUpdater &) = delete;
  AutoUpdater(AutoUpdater &&) = delete;
  AutoUpdater &operator=(const AutoUpdater &) = delete;
  AutoUpdater &operator=(AutoUpdater &&) = delete;

 public:
  virtual ~AutoUpdater();

  virtual void checkForUpdates() = 0;
  virtual void checkForUpdatesNow() = 0;
};

#endif
