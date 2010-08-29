//
//  MapConfigViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 22/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDL_net.h"

@protocol MapConfigDelegate <NSObject>

-(void) buttonPressed:(id) sender;

@end


@interface MapConfigViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    id<MapConfigDelegate> delegate;
    
    TCPsocket sd, csd;
    NSInteger oldValue;  //slider
    NSInteger oldPage;   //segmented control
    BOOL busy;

    // objects read (mostly) by parent view
    NSInteger maxHogs;
    NSString *seedCommand;
    NSString *templateFilterCommand;
    NSString *mapGenCommand;
    NSString *mazeSizeCommand;
    NSString *themeCommand;
    NSString *staticMapCommand;

    // various widgets in the view
    UIButton *previewButton;
    UITableView *tableView;
    UILabel *maxLabel;
    UILabel *sizeLabel;
    UISegmentedControl *segmentedControl;
    UISlider *slider;

    // internal objects
    NSIndexPath *lastIndexPath;
    NSArray *themeArray;
    NSArray *mapArray;
}

@property (nonatomic,retain) id<MapConfigDelegate> delegate;

@property (nonatomic) NSInteger maxHogs;
@property (nonatomic) BOOL busy;
@property (nonatomic,retain) NSString *seedCommand;
@property (nonatomic,retain) NSString *templateFilterCommand;
@property (nonatomic,retain) NSString *mapGenCommand;
@property (nonatomic,retain) NSString *mazeSizeCommand;
@property (nonatomic,retain) NSString *themeCommand;
@property (nonatomic,retain) NSString *staticMapCommand;

@property (nonatomic,retain) IBOutlet UIButton *previewButton;
@property (nonatomic,retain) IBOutlet UITableView *tableView;
@property (nonatomic,retain) IBOutlet UILabel *maxLabel;
@property (nonatomic,retain) IBOutlet UILabel *sizeLabel;
@property (nonatomic,retain) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic,retain) IBOutlet UISlider *slider;

@property (nonatomic,retain) NSIndexPath *lastIndexPath;
@property (nonatomic,retain) NSArray *themeArray;
@property (nonatomic,retain) NSArray *mapArray;

-(IBAction) buttonPressed:(id) sender;

-(IBAction) mapButtonPressed;
-(IBAction) sliderChanged:(id) sender;
-(IBAction) sliderEndedChanging:(id) sender;
-(IBAction) segmentedControlChanged:(id) sender;

-(void) turnOnWidgets;
-(void) turnOffWidgets;
-(void) setLabelText:(NSString *)str;
-(void) setButtonImage:(UIImage *)img;
-(void) updatePreview;
-(void) updatePreviewWithMap:(NSInteger) index;

-(const uint8_t *)engineProtocol:(NSInteger) port;

@end
