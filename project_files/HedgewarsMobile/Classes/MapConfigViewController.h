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
 * File created on 22/04/2010.
 */


#import <UIKit/UIKit.h>
#import "MapPreviewButtonView.h"

@protocol MapConfigDelegate <NSObject>

-(void) buttonPressed:(id) sender;

@end


@interface MapConfigViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MapPreviewViewDelegate> {
    id<MapConfigDelegate> delegate;
    
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
    NSString *missionCommand;

    // various widgets in the view
    MapPreviewButtonView *previewButton;
    UITableView *tableView;
    UILabel *maxLabel;
    UILabel *sizeLabel;
    UISegmentedControl *segmentedControl;
    UISlider *slider;

    // internal objects
    NSIndexPath *lastIndexPath;
    NSArray *dataSourceArray;
}

@property (nonatomic,retain) id<MapConfigDelegate> delegate;

@property (nonatomic,assign) NSInteger maxHogs;
@property (nonatomic,assign) BOOL busy;
@property (nonatomic,retain) NSString *seedCommand;
@property (nonatomic,retain) NSString *templateFilterCommand;
@property (nonatomic,retain) NSString *mapGenCommand;
@property (nonatomic,retain) NSString *mazeSizeCommand;
@property (nonatomic,retain) NSString *themeCommand;
@property (nonatomic,retain) NSString *staticMapCommand;
@property (nonatomic,retain) NSString *missionCommand;

@property (nonatomic,retain) IBOutlet MapPreviewButtonView *previewButton;
@property (nonatomic,retain) IBOutlet UITableView *tableView;
@property (nonatomic,retain) IBOutlet UILabel *maxLabel;
@property (nonatomic,retain) IBOutlet UILabel *sizeLabel;
@property (nonatomic,retain) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic,retain) IBOutlet UISlider *slider;

@property (nonatomic,retain) NSIndexPath *lastIndexPath;
@property (nonatomic,retain) NSArray *dataSourceArray;

-(IBAction) buttonPressed:(id) sender;

-(IBAction) mapButtonPressed;
-(IBAction) sliderChanged:(id) sender;
-(IBAction) sliderEndedChanging:(id) sender;
-(IBAction) segmentedControlChanged:(id) sender;

-(void) turnOnWidgets;
-(void) turnOffWidgets;
-(void) setLabelText:(NSString *)str;
-(void) updatePreview;

@end
