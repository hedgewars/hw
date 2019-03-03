/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2012 Vittorio Giovara <vittorio.giovara@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA.
 */


#import <UIKit/UIKit.h>
#import "MapPreviewButtonView.h"
#import "MNEValueTrackingSlider.h"


@interface MapConfigViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MapPreviewViewDelegate> {
    NSInteger oldValue;     // for the slider
    NSInteger oldPage;      // for the segmented control
    BOOL busy;              // for the preview button

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
    UISegmentedControl *segmentedControl;
    MNEValueTrackingSlider *slider;

    // internal objects
    NSIndexPath *lastIndexPath;
    NSArray *dataSourceArray;
}


@property (nonatomic,assign) NSInteger oldValue;
@property (nonatomic,assign) NSInteger oldPage;
@property (nonatomic,assign) BOOL busy;
@property (nonatomic,assign) NSInteger maxHogs;
@property (nonatomic, strong) NSString *seedCommand;
@property (nonatomic, strong) NSString *templateFilterCommand;
@property (nonatomic, strong) NSString *mapGenCommand;
@property (nonatomic, strong) NSString *mazeSizeCommand;
@property (nonatomic, strong) NSString *themeCommand;
@property (nonatomic, strong) NSString *staticMapCommand;
@property (nonatomic, strong) NSString *missionCommand;

@property (nonatomic, strong) IBOutlet MapPreviewButtonView *previewButton;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UILabel *maxLabel;
@property (nonatomic, strong) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, strong) IBOutlet MNEValueTrackingSlider *slider;

@property (nonatomic, strong) NSIndexPath *lastIndexPath;
@property (nonatomic, strong) NSArray *dataSourceArray;


- (IBAction)mapButtonPressed:(id)sender;
- (IBAction)sliderChanged:(id)sender;
- (IBAction)sliderEndedChanging:(id)sender;
- (IBAction)segmentedControlChanged:(id)sender;

- (void)turnOnWidgets;
- (void)turnOffWidgets;
- (void)setMaxLabelText:(NSString *)str;
- (void)updatePreview;

@end
