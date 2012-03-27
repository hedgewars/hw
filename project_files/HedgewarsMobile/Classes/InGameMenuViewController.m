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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */


#import "InGameMenuViewController.h"
#import "SDL_sysvideo.h"
#import "SDL_uikitkeyboard.h"


#define VIEW_HEIGHT 200

@implementation InGameMenuViewController

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark animating
-(void) present {
    CGRect screen = [[UIScreen mainScreen] bounds];
    self.view.backgroundColor = [UIColor clearColor];
    self.view.frame = CGRectMake(screen.size.height, 0, 200, VIEW_HEIGHT);

    [UIView beginAnimations:@"showing popover" context:NULL];
    [UIView setAnimationDuration:0.35];
    self.view.frame = CGRectMake(screen.size.height-200, 0, 200, VIEW_HEIGHT);
    [UIView commitAnimations];
}

-(void) dismiss {
    if (IS_IPAD() == NO) {
        CGRect screen = [[UIScreen mainScreen] bounds];
        [UIView beginAnimations:@"hiding popover" context:NULL];
        [UIView setAnimationDuration:0.35];
        self.view.frame = CGRectMake(screen.size.height, 0, 200, VIEW_HEIGHT);
        [UIView commitAnimations];
        [self.view performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.35];
    }

    SDL_iPhoneKeyboardHide((SDL_Window *)HW_getSDLWindow());
}

#pragma mark -
#pragma mark tableView methods
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

-(UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"CellIdentifier";

    NSInteger row = [indexPath row];
    NSString *cellTitle;
    if (row == 0)
        cellTitle = NSLocalizedString(@"Show Help", @"");
    else if (row == 1)
        cellTitle = NSLocalizedString(@"Tag", @"");
    else
        cellTitle = NSLocalizedString(@"End Game", @"");

    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (nil == cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:cellIdentifier] autorelease];
    }
    cell.textLabel.text = cellTitle;

    if (IS_IPAD())
        cell.textLabel.textAlignment = UITextAlignmentCenter;

    return cell;
}

-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIActionSheet *actionSheet;

    switch ([indexPath row]) {
        case 0:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"show help ingame" object:nil];

            break;
        case 1:
            HW_chat();
            SDL_iPhoneKeyboardShow((SDL_Window *)HW_getSDLWindow());

            break;
        case 2:
            actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you reeeeeally sure?", @"")
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"Well, maybe not...", @"")
                                        destructiveButtonTitle:NSLocalizedString(@"Of course!", @"")
                                             otherButtonTitles:nil];
            [actionSheet showInView:(IS_IPAD() ? self.view : [HWUtils mainSDLViewInstance])];
            [actionSheet release];

            break;
        default:
            DLog(@"Warning: unset case value in section!");
            break;
    }

    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark actionSheet methods
-(void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger) buttonIndex {
    if ([actionSheet cancelButtonIndex] != buttonIndex) {
        SDL_iPhoneKeyboardHide((SDL_Window *)HW_getSDLWindow());
        HW_terminate(NO);
    }
}

@end
