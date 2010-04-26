//
//  MapConfigViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 22/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDL_net.h"

@interface MapConfigViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    TCPsocket sd, csd;
    unsigned char map[128*32];

    // objects read (mostly) by parent view
    NSInteger maxHogs;
    NSString *seedCommand;
    NSString *templateFilterCommand;
    NSString *mapGenCommand;
    NSString *mazeSizeCommand;
   
    // various widgets in the view
    UIButton *previewButton;
    UITableView *tableView;
    UILabel *maxLabel;
    UILabel *sizeLabel;
    UISegmentedControl *segmentedControl;
    UISlider *slider;
}

@property (nonatomic) NSInteger maxHogs;
@property (nonatomic,retain) NSString *seedCommand;
@property (nonatomic,retain) NSString *templateFilterCommand;
@property (nonatomic,retain) NSString *mapGenCommand;
@property (nonatomic,retain) NSString *mazeSizeCommand;
@property (nonatomic,retain) IBOutlet UIButton *previewButton;
@property (nonatomic,retain) IBOutlet UITableView *tableView;
@property (nonatomic,retain) IBOutlet UILabel *maxLabel;
@property (nonatomic,retain) IBOutlet UILabel *sizeLabel;
@property (nonatomic,retain) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic,retain) IBOutlet UISlider *slider;

-(IBAction) updatePreview;
-(IBAction) sliderChanged:(id) sender;
-(IBAction) sliderEndedChanging:(id) sender;
-(IBAction) segmentedControlChanged:(id) sender;

-(void) engineProtocol:(NSInteger) port;

@end
