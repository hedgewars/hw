    //
//  popupMenuViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 25/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "popupMenuViewController.h"
#import "PascalImports.h"

@implementation popupMenuViewController
@synthesize menuTable;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


-(void) viewDidLoad {
    isPaused = NO;
    menuTable.allowsSelection = YES;
    [super viewDidLoad];
}


- (void)dealloc {
    [menuTable release];
    [super dealloc];
}

#pragma mark -
#pragma mark TableView Methods
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
	
	switch ([indexPath row]) {
		case 0:
            cell.textLabel.text = NSLocalizedString(@"Pause Game", @"");
            //cell.accessoryView = username;
            break;
        case 1:
			cell.textLabel.text = NSLocalizedString(@"Chat", @"");
            //cell.accessoryView = password;
            break;
        case 2:
			cell.textLabel.text = NSLocalizedString(@"End Game", @"");
            break;
        default:
			NSLog(@"Warning: unset case value in kNetworkFields section!");
			break;
    }
	
	return cell;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIActionSheet *actionSheet;
    
    switch ([indexPath row]) {
		case 0:
            HW_pause();
            isPaused = !isPaused;
            break;
        case 1:
			HW_chat();
            break;
        case 2:
			actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you reeeeeally sure?", @"")
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"Well, maybe not...", @"")
                                        destructiveButtonTitle:NSLocalizedString(@"As sure as I can be!", @"")
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
}

- (void)tableView:(UITableView *)aTableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [aTableView deselectRowAtIndexPath: indexPath animated:YES];
}

-(void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger) buttonIndex {
	if ([actionSheet cancelButtonIndex] != buttonIndex)
	    HW_terminate(NO);
	else
        if (!isPaused) 
            HW_pause();		
}


@end
