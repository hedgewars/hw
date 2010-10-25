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
 * File created on 25/03/2010.
 */


#import "SDL_uikitappdelegate.h"
#import "InGameMenuViewController.h"
#import "PascalImports.h"
#import "CommodityFunctions.h"
#import "SDL_sysvideo.h"
#import "SDL_uikitkeyboard.h"

@implementation InGameMenuViewController
@synthesize menuList;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(void) didReceiveMemoryWarning {
    self.menuList = nil;
    [super didReceiveMemoryWarning];
}

-(void) viewDidLoad {
    NSArray *array = [[NSArray alloc] initWithObjects:
                      NSLocalizedString(@"Show Help", @""),
                      NSLocalizedString(@"Tag", @""),
                      NSLocalizedString(@"End Game", @""),
                      nil];
    self.menuList = array;
    [array release];

    // save the sdl window (!= uikit window) for future reference
    SDL_VideoDevice *videoDevice = SDL_GetVideoDevice();
    if (videoDevice) {
        SDL_VideoDisplay *display = &videoDevice->displays[0];
        if (display)
            sdlwindow = display->windows;
    }
    [super viewDidLoad];
}

-(void) viewWillAppear:(BOOL)animated {
    if (sdlwindow == NULL) {
        SDL_VideoDevice *_this = SDL_GetVideoDevice();
        if (_this) {
            SDL_VideoDisplay *display = &_this->displays[0];
            if (display)
                sdlwindow = display->windows;
        }
    }
    [super viewWillAppear:animated];
}

-(void) viewDidUnload {
    self.menuList = nil;
    sdlwindow = NULL;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    [menuList release];
    [super dealloc];
}

#pragma mark -
#pragma mark animating
-(void) present {
    CGRect screen = [[UIScreen mainScreen] bounds];
    self.view.backgroundColor = [UIColor clearColor];
    self.view.frame = CGRectMake(screen.size.height, 0, 200, 170);

    [UIView beginAnimations:@"showing popover" context:NULL];
    [UIView setAnimationDuration:0.35];
    self.view.frame = CGRectMake(screen.size.height-200, 0, 200, 170);
    [UIView commitAnimations];
}

-(void) dismiss {
    CGRect screen = [[UIScreen mainScreen] bounds];
    [UIView beginAnimations:@"hiding popover" context:NULL];
    [UIView setAnimationDuration:0.35];
    self.view.frame = CGRectMake(screen.size.height, 0, 200, 170);
    [UIView commitAnimations];

    [self.view performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.35];

    [self removeChat];
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

    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (nil == cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:cellIdentifier] autorelease];
    }
    cell.textLabel.text = [menuList objectAtIndex:[indexPath row]];

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
            if (SDL_iPhoneKeyboardIsShown(sdlwindow))
                [self removeChat];
            else {
                HW_chat();
                SDL_iPhoneKeyboardShow(sdlwindow);
            }
            break;
        case 2:
            // expand the view (and table) so that the actionsheet can be selected on the iPhone
            if (IS_IPAD()) {
                CGRect screen = [[UIScreen mainScreen] bounds];
                [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                [UIView beginAnimations:@"table width more" context:NULL];
                [UIView setAnimationDuration:0.2];
                self.view.frame = CGRectMake(0, 0, screen.size.height, screen.size.width);
                [UIView commitAnimations];
            }
            actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you reeeeeally sure?", @"")
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"Well, maybe not...", @"")
                                        destructiveButtonTitle:NSLocalizedString(@"Of course!", @"")
                                             otherButtonTitles:nil];
            [actionSheet showInView:self.view];
            [actionSheet release];

            break;
        default:
            DLog(@"Warning: unset case value in section!");
            break;
    }

    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void) removeChat {
    if (SDL_iPhoneKeyboardIsShown(sdlwindow)) {
        SDL_iPhoneKeyboardHide(sdlwindow);
        HW_chatEnd();
    }
}

#pragma mark -
#pragma mark actionSheet methods
-(void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger) buttonIndex {
    if (IS_IPAD()){
        CGRect screen = [[UIScreen mainScreen] bounds];
        [UIView beginAnimations:@"table width less" context:NULL];
        [UIView setAnimationDuration:0.2];
        self.view.frame = CGRectMake(screen.size.height-200, 0, 200, 170);
        [UIView commitAnimations];
    }

    if ([actionSheet cancelButtonIndex] != buttonIndex)
        [[NSNotificationCenter defaultCenter] postNotificationName:@"remove overlay" object:nil];
}

@end
