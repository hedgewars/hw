//
//  SchemeEditViewController.h
//  hwengine
//
//  Created by Vittorio on 08/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SchemeEditViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    UITableViewCell *cell0;
	UITableView *table;
}
@property (nonatomic, retain) IBOutlet UITableViewCell *cell0;
@property (nonatomic, retain) IBOutlet UITableView *table;

@end
