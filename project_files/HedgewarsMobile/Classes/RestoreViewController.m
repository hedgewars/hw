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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */


#import "RestoreViewController.h"
#import "GameInterfaceBridge.h"

@implementation RestoreViewController

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(IBAction) buttonReleased:(id) sender {
    UIButton *theButton = (UIButton *)sender;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (theButton.tag != 0) {
        [AudioManagerController playClickSound];
        [GameInterfaceBridge registerCallingController:self.parentViewController];
        [GameInterfaceBridge startSaveGame:[[NSUserDefaults standardUserDefaults] objectForKey:@"savedGamePath"]];
    } else {
        [AudioManagerController playBackSound];
        [defaults setObject:@"" forKey:@"savedGamePath"];
        [defaults synchronize];
    }
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

-(void) viewDidLoad {
    [super viewDidLoad];
}

-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    [super viewDidUnload];
}

-(void) dealloc {
    [super dealloc];
}


@end
