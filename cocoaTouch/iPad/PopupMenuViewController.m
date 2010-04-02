    //
//  popupMenuViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 25/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SDL_uikitappdelegate.h"
#import "PopupMenuViewController.h"
#import "PascalImports.h"

@implementation PopupMenuViewController
@synthesize menuList;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void) viewDidLoad {
    isPaused = NO;
    self.tableView.allowsSelection = YES;
    self.tableView.alwaysBounceVertical = YES;
    self.tableView.delaysContentTouches = NO;
    menuList = [[NSArray alloc] initWithObjects:
                NSLocalizedString(@"Pause Game", @""),
                NSLocalizedString(@"Chat", @""),
                NSLocalizedString(@"End Game", @""),
                nil];
    [super viewDidLoad];
}


-(void) dealloc {
    [menuList release];
    [super dealloc];
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
			HW_chat();
            //SDL_iPhoneKeyboardShow([SDLUIKitDelegate sharedAppDelegate].window);
            break;
        case 2:
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
			NSLog(@"Warning: unset case value in section!");
			break;
    }
    
    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark actionSheet methods
-(void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger) buttonIndex {
	if ([actionSheet cancelButtonIndex] != buttonIndex) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissPopover" object:nil];
        HW_terminate(NO);
    }
	else
        if (!isPaused) 
            HW_pause();		
}

@end
