//
//  popupMenuViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 25/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface popupMenuViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate> {
    UITableView *menuTable;
    NSArray *menuList;
    BOOL isPaused;
}
@property (nonatomic,retain) IBOutlet UITableView * menuTable;
@property (nonatomic,retain) NSArray *menuList;

@end
