//
//  popupMenuViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 25/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface InGameMenuViewController : UITableViewController <UIActionSheetDelegate> {
    NSArray *menuList;
    BOOL isPaused;
    SDL_Window *sdlwindow;
}

@property (nonatomic,retain) NSArray *menuList;

-(void) present;
-(void) dismiss;
-(void) removeChat;

@end
