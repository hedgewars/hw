/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2010 Vittorio Giovara <vittorio.giovara@gmail.com>
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
 * File created on 03/07/2010.
 */

//http://devblog.wm-innovations.com/2010/03/30/custom-swipe-uitableviewcell/


#import "HoldTableViewCell.h"
#import "CGPointUtils.h"

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
    [self performSelector:@selector(holdAction) withObject:nil afterDelay:0.4];

    [super touchesBegan:touches withEvent:event];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(holdAction)
                                               object:nil];

    [super touchesEnded:touches withEvent:event];
}

-(void) holdAction {
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(holdAction:)])
        [self.delegate holdAction:self.textLabel.text];
}

-(void) dealloc {
    self.delegate = nil;
    [super dealloc];
}

@end
