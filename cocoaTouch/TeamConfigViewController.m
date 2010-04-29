//
//  TeamConfigViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 20/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TeamConfigViewController.h"
#import "CommodityFunctions.h"
#import "HogButtonView.h"
#import "SquareButtonView.h"

@implementation TeamConfigViewController
@synthesize listOfTeams, listOfSelectedTeams;

#define NUMBERBUTTON_TAG 123456
#define SQUAREBUTTON_TAG 654321
#define LABEL_TAG        456123

#pragma mark -
#pragma mark View lifecycle
-(void) viewDidLoad {
    [super viewDidLoad];
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    self.view.frame = CGRectMake(0, 0, screenSize.height, screenSize.width - 44);
    self.tableView.backgroundColor = [UIColor redColor];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // integer representation of various color (defined in SquareButtonView)
    NSUInteger colors[6] = { 4421353, 4100897, 10632635, 16749353, 14483456, 7566195 };
    NSArray *contentsOfDir = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:TEAMS_DIRECTORY() error:NULL];
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[contentsOfDir count]];
    for (int i = 0; i < [contentsOfDir count]; i++) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                                  [contentsOfDir objectAtIndex:i],@"team",
                                                                  [NSNumber numberWithInt:4],@"number",
                                                                  [NSNumber numberWithInt:colors[i%6]],@"color",nil];
        [array addObject:dict];
        [dict release];
    }
    self.listOfTeams = array;
    [array release];
    
    NSMutableArray *emptyArray = [[NSMutableArray alloc] initWithObjects:nil];
    self.listOfSelectedTeams = emptyArray;
    [emptyArray release];

    [self.tableView reloadData];
}

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}


#pragma mark -
#pragma mark Table view data source
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return [listOfSelectedTeams count] ;
    else
        return [listOfTeams count];
}

-(NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return NSLocalizedString(@"Playing Teams",@"");
    else
        return NSLocalizedString(@"Available Teams",@"");
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier0 = @"Cell0";
    static NSString *CellIdentifier1 = @"Cell1";
    NSInteger section = [indexPath section];
    UITableViewCell *cell;
    
    if (section == 0) {
        cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier0];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier0] autorelease];

            UIButton *numberButton = [[HogButtonView alloc] initWithFrame:CGRectMake(12, 5, 88, 32)];
            numberButton.tag = NUMBERBUTTON_TAG;
            [cell addSubview:numberButton];
            [numberButton release];
            
            SquareButtonView *squareButton = [[SquareButtonView alloc] initWithFrame:CGRectMake(12+88+7, 5, 36, 36)];
            squareButton.tag = SQUAREBUTTON_TAG;
            [cell addSubview:squareButton];
            [squareButton release];
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12+88+7+36+7, 10, 250, 25)];
            label.textAlignment = UITextAlignmentLeft;
            label.backgroundColor = [UIColor clearColor];
            label.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize] + 2];
            label.tag = LABEL_TAG;
            [cell.contentView addSubview:label];
            [label release];
        }
        
        NSMutableDictionary *selectedRow = [listOfSelectedTeams objectAtIndex:[indexPath row]];
        
        UILabel *cellLabel = (UILabel *)[cell viewWithTag:LABEL_TAG];
        cellLabel.text = [[selectedRow objectForKey:@"team"] stringByDeletingPathExtension];
        
        HogButtonView *numberButton = (HogButtonView *)[cell viewWithTag:NUMBERBUTTON_TAG];
        [numberButton drawManyHogs:[[selectedRow objectForKey:@"number"] intValue]];
        numberButton.ownerDictionary = selectedRow;
        
        SquareButtonView *squareButton = (SquareButtonView *)[cell viewWithTag:SQUAREBUTTON_TAG];
        [squareButton selectColor:[[selectedRow objectForKey:@"color"] intValue]];
        squareButton.ownerDictionary = selectedRow;
    } else {
        cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier1];
        if (cell == nil) 
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier1] autorelease];
        
        cell.textLabel.text = [[[listOfTeams objectAtIndex:[indexPath row]] objectForKey:@"team"] stringByDeletingPathExtension];
    }

    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark -
#pragma mark Table view delegate
-(void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];

    if (section == 0) {
        [self.listOfTeams addObject:[self.listOfSelectedTeams objectAtIndex:row]];
        [self.listOfSelectedTeams removeObjectAtIndex:row];
    } else {
        [self.listOfSelectedTeams addObject:[self.listOfTeams objectAtIndex:row]];
        [self.listOfTeams removeObjectAtIndex:row];      
    }
    [aTableView reloadData];
}


#pragma mark -
#pragma mark Memory management
-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

-(void) viewDidUnload {
    self.listOfTeams = nil;
}


-(void) dealloc {
    [self.listOfTeams release];
    [super dealloc];
}


@end

