//
//  MapConfigViewController.h
//  HedgewarsMobile
//
//  Created by Vittorio on 22/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDL_net.h"

@interface MapConfigViewController : UIViewController {
    TCPsocket sd, csd;
    NSInteger maxHogs;
    unsigned char map[128*32];

    UIButton *previewButton;
    NSString *seedCommand;
}

@property (nonatomic) NSInteger maxHogs;
@property (nonatomic,retain) UIButton *previewButton;
@property (nonatomic,retain) NSString *seedCommand;

-(IBAction) updatePreview;
-(void) engineProtocol:(NSInteger) port;

@end
