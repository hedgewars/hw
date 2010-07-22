    //
//  popupMenuViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 25/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SDL_uikitappdelegate.h"
#import "InGameMenuViewController.h"
#import "PascalImports.h"
#import "CommodityFunctions.h"
#import "SDL_sysvideo.h"

@implementation InGameMenuViewController
@synthesize menuList;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

-(void) viewDidLoad {
    isPaused = NO;

    NSArray *array = [[NSArray alloc] initWithObjects:
                      NSLocalizedString(@"Pause Game", @""),
                      NSLocalizedString(@"Chat", @""),
                      NSLocalizedString(@"End Game", @""),
                      nil];
    self.menuList = array;
    [array release];
    
    // save the sdl window (!= uikit window) for future reference
    SDL_VideoDevice *_this = SDL_GetVideoDevice();
    SDL_VideoDisplay *display = &_this->displays[0];
    sdlwindow = display->windows;
        
    [super viewDidLoad];
}

-(void) viewDidUnload {
    self.menuList = nil;
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
    
    return cell;
}

-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIActionSheet *actionSheet;
    
    switch ([indexPath row]) {
        case 0:
            HW_pause();
            isPaused = !isPaused;
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
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
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
            
            if (!isPaused) 
                HW_pause();
            break;
        default:
            DLog(@"Warning: unset case value in section!");
            break;
    }
    
    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void) removeChat {
    HW_chatEnd();
    if (SDL_iPhoneKeyboardIsShown(sdlwindow))
        SDL_iPhoneKeyboardHide(sdlwindow);
}

#pragma mark -
#pragma mark actionSheet methods
-(void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger) buttonIndex {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){
        CGRect screen = [[UIScreen mainScreen] bounds];
        [UIView beginAnimations:@"table width less" context:NULL];
        [UIView setAnimationDuration:0.2];
        self.view.frame = CGRectMake(screen.size.height-200, 0, 200, 170);
        [UIView commitAnimations];
    }
    
    if ([actionSheet cancelButtonIndex] != buttonIndex)
        HW_terminate(NO);
    else
        if (!isPaused) 
            HW_pause();     
}

@end
