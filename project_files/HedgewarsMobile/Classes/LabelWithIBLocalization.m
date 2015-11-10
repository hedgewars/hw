/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2015 Anton Malmygin <antonc27@mail.ru>
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
 */

#import "LabelWithIBLocalization.h"

@interface LabelWithIBLocalization ()
@property (nonatomic) BOOL isAlreadyLocalized;
@end

@implementation LabelWithIBLocalization

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!self.isAlreadyLocalized)
    {
        // Text which set in Interface Builder used here as a key for localization
        self.text = NSLocalizedString(self.text, nil);
        
        [self setNeedsLayout];
        self.isAlreadyLocalized = YES;
    }
}

@end
