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


#import <Foundation/Foundation.h>


@interface CreationChamber : NSObject {

}

+ (void)createFirstLaunch;
+ (void)createSettings;

+ (void)createTeamNamed:(NSString *)nameWithoutExt;
+ (void)createTeamNamed:(NSString *)nameWithoutExt ofType:(NSInteger)type;
+ (void)createTeamNamed:(NSString *)nameWithoutExt ofType:(NSInteger)type controlledByAI:(BOOL) shouldAITakeOver;

+ (void)createWeaponNamed:(NSString *)nameWithoutExt;
+ (void)createWeaponNamed:(NSString *)nameWithoutExt ofType:(NSInteger)type;

+ (void)createSchemeNamed:(NSString *)nameWithoutExt;
+ (void)createSchemeNamed:(NSString *)nameWithoutExt ofType:(NSInteger)type;

@end

