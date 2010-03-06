/*
 *  M3Panel.h
 *  
 *
 *  Created by Vittorio on 28/09/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef M3PANEL_H
#define M3PANEL_H

#include "InstallController.h"

class M3Panel : public InstallController
        {
    public:
        M3Panel(void);
        ~M3Panel();
                
        void showInstallController();
                
    private:
        class Private;
        Private* c;
        };

#endif
