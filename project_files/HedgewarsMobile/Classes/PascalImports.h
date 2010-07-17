/*
 *  PascalImports.h
//  fpciphonedel
//
//  Created by Vittorio on 07/01/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
 *
 */

#ifndef PASCALIMPORTS
#define PASCALIMPORTS

#ifdef __cplusplus
extern "C" {
#endif
    
    /* add C declarations below for all exported Pascal functions/procedure
     * that you want to use
     */

    void Game(const char *args[]);
    void GenLandPreview(void);


    void HW_versionInfo(short int*, char**);

    void HW_click(void);
    
    void HW_zoomIn(void);
    void HW_zoomOut(void);
    void HW_zoomReset(void);
    void HW_ammoMenu(void);
    
    void HW_walkingKeysUp(void);
    void HW_otherKeysUp(void);
    void HW_allKeysUp(void);
    
    void HW_walkLeft(void);
    void HW_walkRight(void);
    void HW_aimUp(void);
    void HW_aimDown(void);
    void HW_preciseSet(BOOL status);
    
    void HW_shoot(void);
    void HW_jump(void);
    void HW_backjump(void);
    
    void HW_chat(void);
    void HW_chatEnd(void);
    void HW_tab(void);
    void HW_pause(void);
    
    void HW_cursorUp(int);
    void HW_cursorDown(int);
    void HW_cursorLeft(int);
    void HW_cursorRight(int);
    
    void HW_terminate(BOOL andCloseFrontend);
    
    void HW_setLandscape(BOOL rotate);
    void HW_setCursor(int x, int y);
    void HW_saveCursor(BOOL reset);
    
    BOOL HW_isAmmoOpen(void);
    BOOL HW_isWeaponRequiringClick(void);
    
#ifdef __cplusplus
}
#endif

#endif
