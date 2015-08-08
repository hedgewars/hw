/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2012 Vittorio Giovara <vittorio.giovara@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA.
 */


#ifndef PASCALIMPORTS
#define PASCALIMPORTS

#ifdef __cplusplus
extern "C" {
#endif

    /* add C declarations below for all exported Pascal functions/procedure
     * that you want to use in your non-Pascal code
     */

    void RunEngine(const int argc, const char *argv[]);
    void GenLandPreview(void);
    void LoadLocaleWrapper(const char *filename);

    void HW_versionInfo(int *protoNum, char **versionStr);
    void *HW_getSDLWindow(void);
    void HW_terminate(BOOL andCloseFrontend);

    char *HW_getWeaponNameByIndex(int whichone);
    //char *HW_getWeaponCaptionByIndex(int whichone);
    //char *HW_getWeaponDescriptionByIndex(int whichone);
    int  HW_getNumberOfWeapons(void);
    int  HW_getMaxNumberOfHogs(void);
    int  HW_getMaxNumberOfTeams(void);

    void HW_memoryWarningCallback(void);

#ifdef __cplusplus
}
#endif

#endif
