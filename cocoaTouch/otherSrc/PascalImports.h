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
	
	int HW_protoVer(void);
	
	void HW_click(void);
	void HW_zoomIn(void);
	void HW_zoomOut(void);
	void HW_zoomReset(void);
	void HW_ammoMenu(void);
	
	void HW_allKeysUp(void);
	
	void HW_walkLeft(void);
	void HW_walkRight(void);
	void HW_aimUp(void);
	void HW_aimDown(void);
	void HW_shoot(void);
	
#ifdef __cplusplus
}
#endif

#endif