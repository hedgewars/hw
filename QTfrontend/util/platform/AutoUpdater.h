/*
 * Copyright (C) 2008 Remko Troncon
 */

#ifndef AUTOUPDATER_H
#define AUTOUPDATER_H

class AutoUpdater
{
    public:
        virtual ~AutoUpdater();

        virtual void checkForUpdates() = 0;
        virtual void checkForUpdatesNow() = 0;
};

#endif
