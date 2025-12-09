/*
 * Copyright (C) 2008 Remko Troncon
 */

#ifndef SPARKLEAUTOUPDATER_H
#define SPARKLEAUTOUPDATER_H

#include <QString>

#include "AutoUpdater.h"

class SparkleAutoUpdater : public AutoUpdater
{
    public:
        SparkleAutoUpdater();
        ~SparkleAutoUpdater();

        void checkForUpdates();
        void checkForUpdatesNow();

    private:
        class Private;
        Private* d;
};

#endif
