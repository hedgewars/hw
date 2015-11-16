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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA.
 */

#import "TableViewControllerWithDoneButton.h"

@interface TableViewControllerWithDoneButton ()

@end

@implementation TableViewControllerWithDoneButton

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!IS_IPAD())
    {
        UIBarButtonItem *doneButton = [self doneButton];
        self.navigationItem.backBarButtonItem = doneButton;
        self.navigationItem.leftBarButtonItem = doneButton;
    }
}

- (UIBarButtonItem *)doneButton
{
    return [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                          target:self
                                                          action:@selector(dismissView)] autorelease];
}

- (void)dismissView
{
    [[AudioManagerController mainManager] playBackSound];
    [[[HedgewarsAppDelegate sharedAppDelegate] mainViewController] dismissViewControllerAnimated:YES completion:nil];
}

@end
