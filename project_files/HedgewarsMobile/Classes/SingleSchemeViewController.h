/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2011 Vittorio Giovara <vittorio.giovara@gmail.com>
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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * File created on 23/05/2010.
 */


#import <UIKit/UIKit.h>
#import "EditableCellView.h"

@interface SingleSchemeViewController : UITableViewController <EditableCellViewDelegate> {
    NSString *schemeName;
    NSMutableDictionary *schemeDictionary;
    NSArray *basicSettingList;
    NSArray *gameModifierArray;
}

@property (nonatomic, retain) NSString *schemeName;
@property (nonatomic, retain) NSMutableDictionary *schemeDictionary;
@property (nonatomic, retain) NSArray *basicSettingList;
@property (nonatomic, retain) NSArray *gameModifierArray;

@end
