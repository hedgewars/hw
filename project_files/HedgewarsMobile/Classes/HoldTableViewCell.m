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


#import "HoldTableViewCell.h"
#import "UITableViewCell+FindTable.h"

@implementation HoldTableViewCell
@synthesize delegate;

#define SWIPE_DRAG_HORIZ_MIN 10
#define SWIPE_DRAG_VERT_MAX 40

-(id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        delegate = nil;
    }
    return self;
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];

    time = touch.timestamp;
    [self performSelector:@selector(holdAction) withObject:nil afterDelay:0.25];

    [super touchesBegan:touches withEvent:event];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];

    if ( touch.timestamp - time < 0.25 ) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self
                                                 selector:@selector(holdAction)
                                                   object:nil];

        [super touchesEnded:touches withEvent:event];
    } else
        [super touchesCancelled:touches withEvent:event];
}

-(void) holdAction {
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(holdAction:onTable:)])
    {
        UITableView *tableView = [self findTable];
        if (tableView)
        {
            [self.delegate holdAction:self.textLabel.text onTable:tableView];
        }
    }
}

-(void) dealloc {
    self.delegate = nil;
    [super dealloc];
}

@end
