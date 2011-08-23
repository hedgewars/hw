/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2011 Vittorio Giovara <vittorio.giovara@gmail.com>
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
 * File created on 28/05/2011.
 */


#import "RestoreViewController.h"
#import "GameInterfaceBridge.h"

@implementation RestoreViewController
@synthesize interfaceBridge;

// Override to allow orientations other than the default portrait orientation.
-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}


-(IBAction) buttonReleased:(id) sender {
    UIButton *theButton = (UIButton *)sender;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (theButton.tag != 0) {
        if (self.interfaceBridge == nil) {
            GameInterfaceBridge *bridge = [[GameInterfaceBridge alloc] initWithController:self];
            self.interfaceBridge = bridge;
            [bridge release];
        }
        [self.parentViewController dismissModalViewControllerAnimated:NO];
        [self.interfaceBridge startSaveGame:[defaults objectForKey:@"savedGamePath"]];
    } else {
        [defaults setObject:@"" forKey:@"savedGamePath"];
        [defaults synchronize];
        [self.parentViewController dismissModalViewControllerAnimated:YES];
    }
}

-(void) viewDidLoad {
    NSString *imgName;
    if (IS_IPAD())
        imgName = @"smallerBackground~ipad.png";
    else
        imgName = @"smallerBackground~iphone.png";
    UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgName];
    self.view.backgroundColor = [UIColor colorWithPatternImage:img];
    [img release];
    [super viewDidLoad];
}

-(void) didReceiveMemoryWarning {
    self.interfaceBridge = nil;
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    self.interfaceBridge = nil;
    [super viewDidUnload];
}

-(void) dealloc {
    releaseAndNil(interfaceBridge);
    [super dealloc];
}


@end
